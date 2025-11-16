using System;
using System.IO;
using System.Text;

namespace SecondaryScreenHost.Core
{
    public class DebugLogger : TextWriter
    {
        private readonly TextWriter _originalOutput;
        private readonly StringBuilder _logBuffer = new();
        
        public event EventHandler<string>? LogUpdated;

        public DebugLogger(TextWriter originalOutput)
        {
            _originalOutput = originalOutput;
        }

        public override Encoding Encoding => Encoding.UTF8;

        public override void Write(char value)
        {
            _originalOutput.Write(value);
            _logBuffer.Append(value);
        }

        public override void Write(string? value)
        {
            if (value == null) return;
            
            _originalOutput.Write(value);
            _logBuffer.Append(value);
        }

        public override void WriteLine(string? value)
        {
            if (value == null) return;
            
            var timestamped = $"[{DateTime.Now:HH:mm:ss.fff}] {value}";
            _originalOutput.WriteLine(value);
            _logBuffer.AppendLine(timestamped);
            
            LogUpdated?.Invoke(this, timestamped + Environment.NewLine);
        }

        public string GetFullLog()
        {
            return _logBuffer.ToString();
        }

        public void Clear()
        {
            _logBuffer.Clear();
        }
    }
}
