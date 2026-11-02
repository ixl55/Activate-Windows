# Hide Windows Watermark

A simple command-line (CLI) script that hides the **"Activate Windows"** watermark from the bottom-right corner of the desktop **without activating Windows**, with a one-click undo.

> ⚠️ **Note:** This script does **not** activate Windows. It only hides the watermark. Windows stays unactivated, and personalization settings (wallpaper, colors, themes) remain locked in Settings. To fully activate Windows you need a genuine license.

---

## ✨ Features

- Clear, numbered interactive menu.
- Requests administrator rights automatically.
- Saves a **backup** of the original settings before changing anything.
- **Undo** option that puts everything back exactly as it was.
- Shows activation status and system information.
- Supports direct terminal commands (`/hide`, `/restore`, `/status`).
- No installation needed, no system files modified, no internet connection used.

## 📋 Requirements

- Windows 10 or Windows 11.
- An account with administrator rights.

---

## 🚀 How to Run

### Step 1: Download the script

**Easiest way (ZIP file):**

1. Open the repository page on GitHub.
2. Click the green **Code** button → **Download ZIP**.
3. Open your Downloads folder, right-click the ZIP file → **Extract All**.

**Or with Git:**

```bash
git clone https://github.com/ixl55/Activate-Windows.git
```

### Step 2: Run the script

1. Open the extracted folder.
2. **Double-click** `HideWatermark.cmd`.
3. When the **User Account Control (UAC)** prompt appears, click **Yes**.

> 💡 If a blue **"Windows protected your PC"** screen appears, click **More info** → **Run anyway**.
> This is normal for any file downloaded from the internet.

### Step 3: Hide the watermark

You will see this menu:

```
  ==============================================
        Hide Windows Watermark   v1.0.0
  ==============================================

   Watermark hiding : OFF

   [1] Hide the "Activate Windows" watermark
   [2] Restore original settings - undo
   [3] Show activation status
   [4] Restart the computer now
   [0] Exit

   Select an option:
```

1. Press **1** on your keyboard.
2. Wait for the `[OK] Done` message.
3. Press any key to return to the menu.

### Step 4: Restart your computer

Press **4** and then **Y** to restart, or restart manually.

After the restart, the watermark should be gone ✅

---

## ↩️ Undo (restore everything)

1. Run `HideWatermark.cmd` again.
2. Press **2** (Restore original settings).
3. Restart your computer.

The script restores the original values from the backup saved at:

```
C:\ProgramData\HideWatermark\backup.txt
```

---

## ⌨️ Command-Line Usage (advanced)

Open **CMD** or **PowerShell** **as administrator** (right-click the Start button → Terminal (Admin)), go to the script folder, and run one of these commands:

| Command | Description |
|---|---|
| `HideWatermark.cmd` | Open the interactive menu |
| `HideWatermark.cmd /hide` | Hide the watermark |
| `HideWatermark.cmd /restore` | Undo the changes |
| `HideWatermark.cmd /status` | Show activation and script status |
| `HideWatermark.cmd /help` | Show help |

Example:

```bash
cd "%USERPROFILE%\Downloads\Activate-Windows-main"
```

```bash
HideWatermark.cmd /hide
```

```bash
shutdown /r /t 0
```

> In PowerShell, type `.\HideWatermark.cmd /hide` instead of `HideWatermark.cmd /hide`.

---

## 🔧 What Exactly Does It Change?

The script is fully transparent and changes **only two registry values**:

| Key | Value | New data | Purpose |
|---|---|---|---|
| `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\Activation` | `Manual` | `1` | Turns off automatic activation attempts and prompts, which cause the watermark |
| `HKCU\Control Panel\Desktop` | `PaintDesktopVersion` | `0` | Hides the version text drawn on the desktop |

You can open `HideWatermark.cmd` in Notepad and read every line before running it.

---

## ❓ Troubleshooting

**The watermark is still visible**
- Make sure you **restarted** the computer (not just signed out).
- Press **3** in the menu and check that `Manual` is `1`.
- This method does not work on every PC. You can also try the manual option (Windows 10):
  Control Panel → **Ease of Access** → **Make the computer easier to see** → check **Remove background images** → **Apply**.

**The watermark came back after a Windows update**
Major updates can reset these settings. Run the script and press **1** again.

**`[ERROR] Could not write to the registry`**
Right-click `HideWatermark.cmd` → **Run as administrator**.

**The window opens and closes immediately**
- Make sure you **extracted** the files from the ZIP and are not running the script from inside it.
- If you downloaded the file alone from your browser, make sure its extension is `.cmd` and not `.cmd.txt`.

**I use a standard account and am asked for another administrator's username and password**
In this case the `PaintDesktopVersion` part is applied to the administrator account, not yours. The main part (`Manual`) works machine-wide.

---

## 🛡️ Safety Notes

- **Do not** use unknown tools that patch system files to remove the watermark, such as the many "Watermark Remover" downloads. Many of them contain malware and can break Windows after updates.
- This script does not modify any system files, does not delete anything, and does not connect to the internet.
