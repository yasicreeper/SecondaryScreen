using System;

namespace SecondaryScreenHost.Models
{
    public class DeviceInfo
    {
        public string Name { get; set; } = string.Empty;
        public string IPAddress { get; set; } = string.Empty;
        public string ConnectionType { get; set; } = "WiFi";
        public string DeviceId { get; set; } = string.Empty;
        public bool IsConnected { get; set; }
        
        public override string ToString()
        {
            return $"{Name} ({ConnectionType}) - {IPAddress}";
        }
    }

    public class AppSettings
    {
        public string Resolution { get; set; } = "1024x768";
        public int Quality { get; set; } = 85;
        public int FrameRate { get; set; } = 30;
        public bool AutoStart { get; set; } = false;
        public bool TouchInputEnabled { get; set; } = true;
        public bool AutoConnect { get; set; } = true;
        public string Orientation { get; set; } = "Auto";
        public int Port { get; set; } = 8888;
    }

    public class ScreenFrame
    {
        public byte[] ImageData { get; set; } = Array.Empty<byte>();
        public int Width { get; set; }
        public int Height { get; set; }
        public long Timestamp { get; set; }
    }
}
