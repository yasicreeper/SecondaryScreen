using System;
using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using SecondaryScreenHost.Core;
using SecondaryScreenHost.Models;

namespace SecondaryScreenHost
{
    public partial class MainWindow : Window
    {
        private readonly ServerManager _serverManager;
        private readonly SettingsManager _settingsManager;
        private readonly ObservableCollection<DeviceInfo> _devices;

        public MainWindow()
        {
            InitializeComponent();
            
            _devices = new ObservableCollection<DeviceInfo>();
            DeviceList.ItemsSource = _devices;
            
            _settingsManager = new SettingsManager();
            _serverManager = new ServerManager(_settingsManager);
            
            _serverManager.DeviceConnected += OnDeviceConnected;
            _serverManager.DeviceDisconnected += OnDeviceDisconnected;
            _serverManager.StatusChanged += OnStatusChanged;
            
            LoadSettings();
            UpdateStatusBar("Ready - Click 'Start Server' to begin");
        }

        private void LoadSettings()
        {
            var settings = _settingsManager.LoadSettings();
            
            QualitySlider.Value = settings.Quality;
            FpsSlider.Value = settings.FrameRate;
            AutoStartCheck.IsChecked = settings.AutoStart;
            TouchInputCheck.IsChecked = settings.TouchInputEnabled;
            AutoConnectCheck.IsChecked = settings.AutoConnect;
            
            SetComboBoxByTag(ResolutionCombo, settings.Resolution);
            SetComboBoxByTag(OrientationCombo, settings.Orientation);
        }

        private void SetComboBoxByTag(ComboBox combo, string value)
        {
            foreach (ComboBoxItem item in combo.Items)
            {
                if (item.Content.ToString() == value)
                {
                    combo.SelectedItem = item;
                    break;
                }
            }
        }

        private void StartServer_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                _serverManager.StartServer();
                StartServerBtn.IsEnabled = false;
                StopServerBtn.IsEnabled = true;
                
                var localIP = _serverManager.GetLocalIPAddress();
                WifiIPText.Text = $"📶 WiFi IP: {localIP}:8888";
                
                UpdateStatus("Server started - Ready for connections", Brushes.Green);
                UpdateStatusBar($"✓ Server running at {localIP}:8888 - Enter this IP on your iPad");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to start server: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void StopServer_Click(object sender, RoutedEventArgs e)
        {
            _serverManager.StopServer();
            StartServerBtn.IsEnabled = true;
            StopServerBtn.IsEnabled = false;
            
            WifiIPText.Text = "WiFi IP: Not started";
            UsbStatusText.Text = "USB: Not connected";
            
            UpdateStatus("Server stopped", Brushes.Gray);
            UpdateStatusBar("Server stopped");
            
            _devices.Clear();
        }

        private void RefreshDevices_Click(object sender, RoutedEventArgs e)
        {
            _devices.Clear();
            var devices = _serverManager.GetAvailableDevices();
            
            foreach (var device in devices)
            {
                _devices.Add(device);
            }
            
            UpdateStatusBar($"Found {devices.Count} device(s)");
        }

        private void DeviceList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (DeviceList.SelectedItem is DeviceInfo device)
            {
                UpdateStatusBar($"Selected: {device.Name}");
            }
        }

        private void ResolutionCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (IsLoaded && ResolutionCombo.SelectedItem is ComboBoxItem item)
            {
                UpdateStatusBar($"Resolution set to {item.Content}");
                ApplySettingsImmediately();
            }
        }

        private void QualitySlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if (IsLoaded && StatusBarText != null)
            {
                UpdateStatusBar($"Quality set to {(int)e.NewValue}%");
                ApplySettingsImmediately();
            }
        }

        private void FpsSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if (IsLoaded && StatusBarText != null)
            {
                UpdateStatusBar($"Frame rate set to {(int)e.NewValue} FPS");
                ApplySettingsImmediately();
            }
        }

        private void AutoStartCheck_Changed(object sender, RoutedEventArgs e)
        {
            if (IsLoaded && StatusBarText != null)
            {
                UpdateStatusBar($"Auto-start {(AutoStartCheck.IsChecked == true ? "enabled" : "disabled")}");
                ApplySettingsImmediately();
            }
        }

        private void TouchInputCheck_Changed(object sender, RoutedEventArgs e)
        {
            if (IsLoaded && StatusBarText != null)
            {
                UpdateStatusBar($"Touch input {(TouchInputCheck.IsChecked == true ? "enabled" : "disabled")}");
                ApplySettingsImmediately();
            }
        }

        private void AutoConnectCheck_Changed(object sender, RoutedEventArgs e)
        {
            if (IsLoaded && StatusBarText != null)
            {
                UpdateStatusBar($"Auto-connect {(AutoConnectCheck.IsChecked == true ? "enabled" : "disabled")}");
                ApplySettingsImmediately();
            }
        }

        private void OrientationCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (IsLoaded && OrientationCombo.SelectedItem is ComboBoxItem item && StatusBarText != null)
            {
                UpdateStatusBar($"Orientation set to {item.Content}");
                ApplySettingsImmediately();
            }
        }

        private void ApplySettings_Click(object sender, RoutedEventArgs e)
        {
            var settings = new AppSettings
            {
                Resolution = (ResolutionCombo.SelectedItem as ComboBoxItem)?.Content.ToString() ?? "1024x768",
                Quality = (int)QualitySlider.Value,
                FrameRate = (int)FpsSlider.Value,
                AutoStart = AutoStartCheck.IsChecked == true,
                TouchInputEnabled = TouchInputCheck.IsChecked == true,
                AutoConnect = AutoConnectCheck.IsChecked == true,
                Orientation = (OrientationCombo.SelectedItem as ComboBoxItem)?.Content.ToString() ?? "Auto",
                Port = 8888
            };
            
            _settingsManager.SaveSettings(settings);
            _serverManager.ApplySettings(settings);
            
            MessageBox.Show("Settings saved and will persist on restart!", "Settings Saved", 
                MessageBoxButton.OK, MessageBoxImage.Information);
            UpdateStatusBar("Settings saved to disk");
        }

        private void OnDeviceConnected(object? sender, DeviceInfo device)
        {
            Dispatcher.Invoke(() =>
            {
                _devices.Add(device);
                UpdateStatus($"Connected: {device.Name}", Brushes.Green);
                DeviceInfo.Text = $"{device.Name} - {device.ConnectionType}";
                UsbStatusText.Text = device.ConnectionType == "USB" 
                    ? "USB: Connected" 
                    : "USB: Not connected";
                UpdateStatusBar($"Device connected: {device.Name}");
            });
        }

        private void OnDeviceDisconnected(object? sender, DeviceInfo device)
        {
            Dispatcher.Invoke(() =>
            {
                _devices.Remove(device);
                UpdateStatus("Waiting for connection...", Brushes.Orange);
                DeviceInfo.Text = "No device connected";
                UpdateStatusBar($"Device disconnected: {device.Name}");
            });
        }

        private void OnStatusChanged(object? sender, string status)
        {
            Dispatcher.Invoke(() =>
            {
                UpdateStatusBar(status);
                
                // Update USB status if message contains USB info
                if (status.Contains("USB:", StringComparison.OrdinalIgnoreCase))
                {
                    if (status.Contains("detected", StringComparison.OrdinalIgnoreCase))
                    {
                        UsbStatusText.Text = "USB: Apple device connected";
                    }
                    else
                    {
                        UsbStatusText.Text = "USB: Not connected";
                    }
                }
            });
        }

        private void UpdateStatus(string text, Brush color)
        {
            StatusText.Text = text;
            StatusIndicator.Fill = color;
        }

        private void UpdateStatusBar(string text)
        {
            StatusBarText.Text = $"{DateTime.Now:HH:mm:ss} - {text}";
        }

        private void ApplySettingsImmediately()
        {
            if (!IsLoaded) return;

            var settings = new AppSettings
            {
                Resolution = (ResolutionCombo.SelectedItem as ComboBoxItem)?.Content.ToString() ?? "1024x768",
                Quality = (int)QualitySlider.Value,
                FrameRate = (int)FpsSlider.Value,
                AutoStart = AutoStartCheck.IsChecked == true,
                TouchInputEnabled = TouchInputCheck.IsChecked == true,
                AutoConnect = AutoConnectCheck.IsChecked == true,
                Orientation = (OrientationCombo.SelectedItem as ComboBoxItem)?.Content.ToString() ?? "Auto",
                Port = 8888
            };

            _serverManager.ApplySettings(settings);
        }

        protected override void OnClosed(EventArgs e)
        {
            _serverManager?.Dispose();
            base.OnClosed(e);
        }
    }
}
