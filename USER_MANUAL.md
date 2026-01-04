# InTune User Manual

## 📱 Overview

**InTune** is an ultra-fast, local-first connectivity suite that connects your **Android phone** and **Windows PC** over WiFi. Transfer files, sync clipboard, control your PC remotely, and more — all without internet!

---

## 🚀 Features

| Feature | Description |
|---------|-------------|
| **File Transfer** | Send files between phone and PC at LAN speeds |
| **Universal Clipboard** | Copy on one device, paste on other |
| **Remote Trackpad** | Control PC cursor from your phone |
| **Remote Keyboard** | Type on PC using phone keyboard |
| **Quick Actions** | Mute, Task View, Close Windows (ALT+F4) |
| **Transfer History** | Track all sent/received files |

---

## 📥 Installation

### Android

1. Download `InTune_Android_v1.0.apk`
2. Enable "Install from Unknown Sources" if prompted
3. Install and open the app
4. Grant permissions (Storage, Nearby Devices, Notifications)

### Windows

1. Download `InTune_Setup_v1.0.exe`
2. Run the installer
3. Allow through Windows Firewall if prompted
4. App starts automatically and minimizes to system tray

---

## 🔗 Connecting Devices

### Step 1: Start Windows App

1. Open InTune on Windows
2. Note the **IP Address** displayed (e.g., `192.168.1.100`)

### Step 2: Connect from Android

1. Open InTune on Android
2. Go to **Radar** tab
3. Enter the IP address shown on Windows
4. Tap **CONNECT**

### Step 3: Verify Connection

- Windows shows "Connected to [Android Device Name]"
- Android shows "🟢 Connected to [PC Name]"

---

## 📂 File Transfer

### Send File from Android to PC

1. Go to **Dashboard** tab
2. Tap **Quick Drop** button
3. Select file(s) to send
4. Files appear in PC's download folder

### Send File from PC to Android

1. Drag and drop files onto the Windows app
2. Files are saved to Android's InTune folder

### View Transfer History

1. Go to **Files** tab (Android) or **Transfers** tab (Windows)
2. See all sent/received files
3. Tap to open file or folder

---

## 📋 Clipboard Sync

### Manual Sync

1. Copy text on either device
2. Go to **Dashboard** tab on Android
3. Tap **SEND** to push phone clipboard to PC
4. Tap **GET FROM PC** to pull PC clipboard to phone

### Auto Sync

1. Toggle **Auto Sync** switch on Dashboard
2. Clipboard syncs automatically every 2 seconds (foreground only)

---

## 🎮 Remote Control

### Trackpad

1. Go to **Remote** tab on Android
2. Swipe on trackpad area to move cursor
3. Tap to left-click
4. Use scroll strip on right for scrolling

### Keyboard

1. Tap **KEYBOARD** button at bottom
2. Type on phone keyboard to input text on PC
3. Supports Backspace, Enter, Escape keys

### Quick Actions

| Button | Action |
|--------|--------|
| MUTE | Toggle PC volume mute |
| TASK VIEW | Open Windows Task View (Win+Tab) |
| CLOSE | Close active window (Alt+F4) |

### Sensitivity

- Use the slider to adjust cursor sensitivity (0.5x to 3.0x)

---

## ⚙️ Settings

### Android

- Device Name: Change how your phone appears to other devices
- Storage Path: Choose where received files are saved

### Windows

- Download Path: Set where received files are saved
- Launch at Startup: Runs automatically when Windows starts
- System Tray: Minimizes to tray instead of closing

---

## ❓ Troubleshooting

### Connection Failed

- Ensure both devices are on **same WiFi network**
- Check Windows Firewall allows InTune
- Verify IP address is entered correctly
- Try restarting both apps

### Files Not Transferring

- Check storage permissions on Android
- Verify download folder exists and is writable
- Check available storage space

### Trackpad Not Moving Cursor

- Ensure connection is active (check Dashboard status)
- Try increasing sensitivity
- Restart the Remote tab

### Clipboard Not Syncing

- Ensure connection is active
- Android: Check notification permission (for background sync)
- Try manual sync buttons first

---

##  Support

For issues or feedback, contact the developer.
krishp6777@gmail.com
---

**Version:** 1.0.0  
**Platforms:** Android, Windows
