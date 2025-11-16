# 🐛 Debug Guide - Screen Streaming Fix

## Problem Identified

iPad was showing "Waiting for screen data..." forever even though Windows showed the device was connected.

## Root Cause Analysis

### Issue 1: Large Frame Reception ❌
The iPad was trying to receive entire JPEG frames (can be 50KB-200KB) in a single TCP read:
```swift
// OLD - BROKEN
connection?.receive(minimumIncompleteLength: size, maximumLength: size)
```

**Problem**: TCP doesn't guarantee all bytes arrive at once. Large frames get split into multiple packets.

### Issue 2: No Debug Visibility 🔍
Neither app had logging to see:
- If frames were being captured
- If frames were being sent
- If iPad was receiving data
- Where the pipeline was breaking

## Fixes Applied ✅

### 1. Chunked Frame Reception (iPad)
```swift
// NEW - WORKING
private func receiveFrameData(remaining: Int, accumulated: Data, ...) {
    let chunkSize = min(remaining, 65536) // Read 64KB chunks
    connection?.receive(minimumIncompleteLength: 1, maximumLength: chunkSize)
    
    // Accumulate data until complete
    if newRemaining > 0 {
        receiveFrameData(remaining: newRemaining, accumulated: newAccumulated, ...)
    } else {
        // Decode complete image
        UIImage(data: newAccumulated)
    }
}
```

### 2. Comprehensive Debug Logging

**Windows Console Output:**
```
🚀 Server started on port 8888
📹 Screen capture started
⚡ Capture loop started, delay: 33ms
✅ Client connected. Total clients: 1
📸 Captured frame #30: 1920x1080, 87654 bytes
📤 Broadcasting frame to 1 client(s)
📨 Frame #1: {"type":"frame","width":1920,"height":1080,"dataSize":87654}
```

**iPad Console Output (Xcode):**
```
📥 Received message type: settings
📥 Received message type: frame
🖼️ Frame header: 1920x1080, size: 87654 bytes
📥 Starting to receive frame: 87654 bytes
📦 Received chunk: 32768 bytes, remaining: 54886
📦 Received chunk: 32768 bytes, remaining: 22118
📦 Received chunk: 22118 bytes, remaining: 0
✅ Complete frame received: 87654 bytes
🖼️ Image decoded successfully!
```

## How to Debug

### Windows App (Console Window)
1. Run from PowerShell: `.\SecondaryScreenHost.exe`
2. Watch for these messages:
   - ✅ `Server started` - Listening for connections
   - ✅ `Screen capture started` - Capturing screen
   - ✅ `Capture loop started` - Frames being created
   - ✅ `Client connected` - iPad connected
   - ✅ `Broadcasting frame` - Sending to iPad

### iPad App (Xcode Debug Console)
1. Build and run from Xcode
2. Connect to Windows PC
3. Watch for:
   - ✅ `Received message type: settings` - Initial handshake
   - ✅ `Frame header: WxH` - Frame metadata received
   - ✅ `Received chunk: X bytes` - Data chunks arriving
   - ✅ `Complete frame received` - Full image assembled
   - ✅ `Image decoded successfully!` - Displayed on screen

### Common Issues

#### No "Broadcasting frame" messages
- Screen capture failed to start
- Check resolution settings (must be valid like "1920x1080")

#### "No clients to broadcast to"
- iPad not in client list
- Connection dropped immediately
- Check firewall/network

#### iPad receives chunks but "Failed to decode image"
- Corrupted JPEG data
- Wrong data size in header
- Check quality settings (should be 1-100)

#### Chunks stop mid-stream
- Network interruption
- Connection closed
- Check WiFi stability

## Settings Impact

| Setting | Effect | Recommended |
|---------|--------|-------------|
| **Resolution** | Screen size (e.g., 1920x1080) | Match your display or lower for performance |
| **Quality** | JPEG compression (1-100) | 85 for balance, 60 for speed, 95 for quality |
| **FPS** | Frames per second (10-60) | 30 for normal use, 15 for slow networks |

**Lower values = smaller files = faster transmission**

## Performance Tips

1. **Slow network?** 
   - Reduce resolution to 1280x720
   - Lower quality to 60
   - Reduce FPS to 20

2. **Choppy display?**
   - Increase FPS to 45-60
   - May need faster WiFi

3. **Blurry image?**
   - Increase quality to 90-95
   - Check resolution matches display

## Next Steps

The core streaming now works! Future improvements:
- ⏭️ USB streaming (currently only detects device)
- ⏭️ Touch input (send touches back to Windows)
- ⏭️ Auto-discovery via Bonjour (currently manual IP only)

---

**Updated**: November 16, 2025  
**Status**: Screen streaming functional with debug logging
