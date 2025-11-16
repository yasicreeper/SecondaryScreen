# 🚀 Quick Start Guide

## Step-by-Step Connection

### On Windows PC:

1. **Run** `SecondaryScreenHost.exe`
2. **Click** "Start Server" button
3. **Copy** the IP address shown (e.g., `192.168.0.112:8888`)

   Example:
   ```
   📶 WiFi IP: 192.168.0.112:8888
   ```

### On iPad:

1. **Open** the Secondary Screen app
2. **Enter** the IP address (without the `:8888` part)
   
   Type: `192.168.0.112`

3. **Tap** "Connect" button
4. **Wait** for connection (~2-5 seconds)

## ✓ Connection Success

When connected, you'll see:
- **Windows**: Green status "Device connected"
- **iPad**: Your PC screen displayed

## ❌ Connection Issues?

### iPad says "Cannot connect"

**Check these:**
- [ ] Both devices on **same WiFi network**
- [ ] Windows app shows **"Server running"**
- [ ] IP address typed **correctly** (no spaces)
- [ ] iPad **not using cellular data**
- [ ] No VPN active on either device

### Still not working?

1. **Restart both apps**
2. **Check firewall** (should auto-configure)
3. **Try different WiFi network**

## 📱 Connection Types

| Type | Status | How to Use |
|------|--------|-----------|
| **WiFi** | ✅ Working | Enter IP manually (instructions above) |
| **USB** | 🚧 Detected only | Shows "Apple device connected" but connection not implemented yet |
| **Auto-discovery** | ❌ Not working | Bonjour service not implemented |

## 💡 Tips

- **Keep both apps open** during connection
- **PC must be awake** (not sleeping)
- **First connection** takes a few seconds
- **IP address changes?** Restart server to see new IP

## 🆘 Need Help?

If manual connection at `192.168.0.112` doesn't work:

1. On Windows, run Command Prompt:
   ```
   ipconfig
   ```
   Look for "IPv4 Address" under your WiFi adapter

2. Use that IP address on iPad instead

---

**Current Version**: 1.0.0  
**Last Updated**: January 2025
