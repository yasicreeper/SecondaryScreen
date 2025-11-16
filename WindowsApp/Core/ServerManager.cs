using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Net.NetworkInformation;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Management;
using Newtonsoft.Json;
using SecondaryScreenHost.Models;

namespace SecondaryScreenHost.Core
{
    public class ServerManager : IDisposable
    {
        private TcpListener? _listener;
        private readonly List<ClientConnection> _clients = new();
        private readonly SettingsManager _settingsManager;
        private AppSettings _settings;
        private CancellationTokenSource? _cancellationTokenSource;
        private ScreenCaptureService? _screenCapture;
        private bool _isRunning;
        private System.Threading.Timer? _usbCheckTimer;

        public event EventHandler<DeviceInfo>? DeviceConnected;
        public event EventHandler<DeviceInfo>? DeviceDisconnected;
        public event EventHandler<string>? StatusChanged;

        public ServerManager(SettingsManager settingsManager)
        {
            _settingsManager = settingsManager;
            _settings = _settingsManager.LoadSettings();
        }

        public void StartServer()
        {
            if (_isRunning) return;

            _cancellationTokenSource = new CancellationTokenSource();
            _listener = new TcpListener(IPAddress.Any, _settings.Port);
            _listener.Start();
            _isRunning = true;

            StatusChanged?.Invoke(this, "Server started");

            Task.Run(() => AcceptClientsAsync(_cancellationTokenSource.Token));
            
            _screenCapture = new ScreenCaptureService(_settings);
            _screenCapture.SetFrameCallback(BroadcastFrame);
            _screenCapture.StartCapture();
            
            // Start USB device monitoring
            _usbCheckTimer = new System.Threading.Timer(CheckUSBDevices, null, 0, 5000);
        }

        private void CheckUSBDevices(object? state)
        {
            try
            {
                var usbDevices = GetUSBDevices();
                var hasAppleDevice = usbDevices.Any(d => 
                    d.Contains("Apple", StringComparison.OrdinalIgnoreCase) ||
                    d.Contains("iPad", StringComparison.OrdinalIgnoreCase) ||
                    d.Contains("iPhone", StringComparison.OrdinalIgnoreCase));
                
                if (hasAppleDevice)
                {
                    StatusChanged?.Invoke(this, "USB: Apple device detected");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"USB check error: {ex.Message}");
            }
        }

        private List<string> GetUSBDevices()
        {
            var devices = new List<string>();
            
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_PnPEntity WHERE PNPClass='USB' OR PNPClass='WPD'"))
                {
                    foreach (ManagementObject device in searcher.Get())
                    {
                        var name = device["Name"]?.ToString();
                        if (!string.IsNullOrEmpty(name))
                        {
                            devices.Add(name);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting USB devices: {ex.Message}");
            }
            
            return devices;
        }

        public void StopServer()
        {
            if (!_isRunning) return;

            _isRunning = false;
            _cancellationTokenSource?.Cancel();
            _listener?.Stop();
            _screenCapture?.StopCapture();
            _usbCheckTimer?.Dispose();

            foreach (var client in _clients.ToList())
            {
                client.Disconnect();
            }
            _clients.Clear();

            StatusChanged?.Invoke(this, "Server stopped");
        }

        private async Task AcceptClientsAsync(CancellationToken cancellationToken)
        {
            while (!cancellationToken.IsCancellationRequested && _isRunning)
            {
                try
                {
                    var tcpClient = await _listener!.AcceptTcpClientAsync();
                    var client = new ClientConnection(tcpClient, this);
                    
                    _clients.Add(client);
                    
                    var deviceInfo = new DeviceInfo
                    {
                        Name = $"iPad-{_clients.Count}",
                        IPAddress = ((IPEndPoint)tcpClient.Client.RemoteEndPoint!).Address.ToString(),
                        ConnectionType = "WiFi",
                        DeviceId = Guid.NewGuid().ToString(),
                        IsConnected = true
                    };
                    
                    client.DeviceInfo = deviceInfo;
                    DeviceConnected?.Invoke(this, deviceInfo);
                    
                    // Send initial settings to iPad
                    SendSettingsToClient(client);
                    
                    _ = Task.Run(() => client.StartReceiving(cancellationToken));
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    StatusChanged?.Invoke(this, $"Error accepting client: {ex.Message}");
                }
            }
        }

        internal void OnClientDisconnected(ClientConnection client)
        {
            _clients.Remove(client);
            if (client.DeviceInfo != null)
            {
                DeviceDisconnected?.Invoke(this, client.DeviceInfo);
            }
        }

        private void SendSettingsToClient(ClientConnection client)
        {
            var settingsMessage = new
            {
                type = "settings",
                resolution = _settings.Resolution,
                quality = _settings.Quality,
                frameRate = _settings.FrameRate,
                touchEnabled = _settings.TouchInputEnabled,
                orientation = _settings.Orientation
            };
            
            var json = JsonConvert.SerializeObject(settingsMessage);
            client.SendMessage(json);
        }

        public void ApplySettings(AppSettings settings)
        {
            _settings = settings;
            _screenCapture?.UpdateSettings(settings);
            
            // Send updated settings to all connected clients
            foreach (var client in _clients)
            {
                SendSettingsToClient(client);
            }
        }

        public string GetLocalIPAddress()
        {
            var host = Dns.GetHostEntry(Dns.GetHostName());
            foreach (var ip in host.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork)
                {
                    return ip.ToString();
                }
            }
            return "127.0.0.1";
        }

        public List<DeviceInfo> GetAvailableDevices()
        {
            return _clients
                .Where(c => c.DeviceInfo != null)
                .Select(c => c.DeviceInfo!)
                .ToList();
        }

        public void BroadcastFrame(ScreenFrame frame)
        {
            foreach (var client in _clients.ToList())
            {
                try
                {
                    client.SendFrame(frame);
                }
                catch
                {
                    // Client disconnected, will be handled by ClientConnection
                }
            }
        }

        public void Dispose()
        {
            StopServer();
            _cancellationTokenSource?.Dispose();
            _screenCapture?.Dispose();
            _usbCheckTimer?.Dispose();
        }
    }

    internal class ClientConnection
    {
        private readonly TcpClient _tcpClient;
        private readonly NetworkStream _stream;
        private readonly ServerManager _server;

        public DeviceInfo? DeviceInfo { get; set; }

        public ClientConnection(TcpClient tcpClient, ServerManager server)
        {
            _tcpClient = tcpClient;
            _stream = tcpClient.GetStream();
            _server = server;
        }

        public async Task StartReceiving(CancellationToken cancellationToken)
        {
            var buffer = new byte[8192];
            
            try
            {
                while (!cancellationToken.IsCancellationRequested && _tcpClient.Connected)
                {
                    var bytesRead = await _stream.ReadAsync(buffer, 0, buffer.Length, cancellationToken);
                    
                    if (bytesRead == 0)
                    {
                        break; // Connection closed
                    }
                    
                    var message = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                    ProcessMessage(message);
                }
            }
            catch (Exception)
            {
                // Connection error
            }
            finally
            {
                Disconnect();
            }
        }

        private void ProcessMessage(string message)
        {
            try
            {
                dynamic? data = JsonConvert.DeserializeObject(message);
                
                if (data?.type == "touch")
                {
                    // Handle touch input from iPad
                    // TODO: Implement mouse input simulation
                }
                else if (data?.type == "info")
                {
                    // Update device info
                    if (DeviceInfo != null)
                    {
                        DeviceInfo.Name = data.deviceName ?? DeviceInfo.Name;
                    }
                }
            }
            catch
            {
                // Invalid message format
            }
        }

        public void SendMessage(string message)
        {
            try
            {
                var bytes = Encoding.UTF8.GetBytes(message + "\n");
                _stream.Write(bytes, 0, bytes.Length);
            }
            catch
            {
                Disconnect();
            }
        }

        public void SendFrame(ScreenFrame frame)
        {
            try
            {
                // Send frame header
                var header = new
                {
                    type = "frame",
                    width = frame.Width,
                    height = frame.Height,
                    timestamp = frame.Timestamp,
                    dataSize = frame.ImageData.Length
                };
                
                var headerJson = JsonConvert.SerializeObject(header);
                var headerBytes = Encoding.UTF8.GetBytes(headerJson + "\n");
                
                _stream.Write(headerBytes, 0, headerBytes.Length);
                
                // Send frame data
                _stream.Write(frame.ImageData, 0, frame.ImageData.Length);
                _stream.Flush();
            }
            catch
            {
                Disconnect();
            }
        }

        public void Disconnect()
        {
            try
            {
                _stream.Close();
                _tcpClient.Close();
                _server.OnClientDisconnected(this);
            }
            catch
            {
                // Already disconnected
            }
        }
    }
}
