using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using SecondaryScreenHost.Models;

namespace SecondaryScreenHost.Core
{
    public class ScreenCaptureService : IDisposable
    {
        private AppSettings _settings;
        private CancellationTokenSource? _cancellationTokenSource;
        private bool _isCapturing;
        private readonly ServerManager? _serverManager;

        [DllImport("user32.dll")]
        private static extern IntPtr GetDesktopWindow();

        [DllImport("user32.dll")]
        private static extern IntPtr GetWindowDC(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool ReleaseDC(IntPtr hWnd, IntPtr hDC);

        [DllImport("gdi32.dll")]
        private static extern bool BitBlt(IntPtr hdcDest, int xDest, int yDest, int wDest, int hDest,
            IntPtr hdcSource, int xSrc, int ySrc, CopyPixelOperation rop);

        public ScreenCaptureService(AppSettings settings, ServerManager? serverManager = null)
        {
            _settings = settings;
            _serverManager = serverManager;
        }

        public void StartCapture()
        {
            if (_isCapturing) return;

            _isCapturing = true;
            _cancellationTokenSource = new CancellationTokenSource();
            
            Task.Run(() => CaptureLoop(_cancellationTokenSource.Token));
        }

        public void StopCapture()
        {
            _isCapturing = false;
            _cancellationTokenSource?.Cancel();
        }

        public void UpdateSettings(AppSettings settings)
        {
            _settings = settings;
        }

        private async Task CaptureLoop(CancellationToken cancellationToken)
        {
            var frameDelay = 1000 / _settings.FrameRate;
            
            while (!cancellationToken.IsCancellationRequested && _isCapturing)
            {
                try
                {
                    var frame = CaptureScreen();
                    _serverManager?.BroadcastFrame(frame);
                    
                    await Task.Delay(frameDelay, cancellationToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Capture error: {ex.Message}");
                    await Task.Delay(100, cancellationToken);
                }
            }
        }

        private ScreenFrame CaptureScreen()
        {
            // Parse resolution
            var resParts = _settings.Resolution.Split('x');
            var width = int.Parse(resParts[0]);
            var height = int.Parse(resParts[1]);

            // Capture the primary screen
            var bounds = System.Windows.Forms.Screen.PrimaryScreen!.Bounds;
            var bitmap = new Bitmap(bounds.Width, bounds.Height, PixelFormat.Format32bppArgb);
            
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.CopyFromScreen(bounds.Left, bounds.Top, 0, 0, bounds.Size);
            }

            // Resize if needed
            if (bitmap.Width != width || bitmap.Height != height)
            {
                var resized = new Bitmap(width, height);
                using (var graphics = Graphics.FromImage(resized))
                {
                    graphics.DrawImage(bitmap, 0, 0, width, height);
                }
                bitmap.Dispose();
                bitmap = resized;
            }

            // Compress to JPEG
            byte[] imageData;
            using (var ms = new MemoryStream())
            {
                var encoder = GetEncoder(ImageFormat.Jpeg);
                var encoderParams = new EncoderParameters(1);
                encoderParams.Param[0] = new EncoderParameter(
                    System.Drawing.Imaging.Encoder.Quality, 
                    (long)_settings.Quality);
                
                bitmap.Save(ms, encoder, encoderParams);
                imageData = ms.ToArray();
            }

            bitmap.Dispose();

            return new ScreenFrame
            {
                ImageData = imageData,
                Width = width,
                Height = height,
                Timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            };
        }

        private static ImageCodecInfo GetEncoder(ImageFormat format)
        {
            var codecs = ImageCodecInfo.GetImageDecoders();
            foreach (var codec in codecs)
            {
                if (codec.FormatID == format.Guid)
                {
                    return codec;
                }
            }
            return codecs[0];
        }

        public void Dispose()
        {
            StopCapture();
            _cancellationTokenSource?.Dispose();
        }
    }
}
