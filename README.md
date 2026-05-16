![WinWarp Logo](https://github.com/matt973/winwarp/raw/main/winwarp.png)

# WinWarp 🚀

**Quick boot to Windows from Batocera Linux via EFI boot manager**

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Shell](https://img.shields.io/badge/language-Bash-green.svg)
![Platform](https://img.shields.io/badge/platform-Batocera%20Linux-blue.svg)
![EFI](https://img.shields.io/badge/boot-EFI%20%7C%20rEFInd-orange.svg)

WinWarp is a lightweight bash script that lets you reboot directly into Windows from Batocera Linux with a single click — no BIOS/UEFI settings, no manual boot order changes.

---

## ✨ Features

- Automatically detects the Windows EFI boot entry (`bootmgfw.efi` / Windows Boot Manager)
- Sets Windows as the **next boot only once** (via `BootNext`) — Batocera resumes as default on the following reboot
- Compatible with standard **EFI boot manager** and **rEFInd**
- Displays a custom splash screen before rebooting (supports `mpv`, `fbi`, `fim` with automatic fallback)
- Appears directly in the **Ports** section of EmulationStation with artwork and marquee
- Simple one-line installation via SSH — no manual configuration needed

---

## 📋 Requirements

- Batocera Linux installed on a **UEFI system**
- Windows installed on the same machine with its own EFI entry
- `efibootmgr` available on the system (usually pre-installed on Batocera)
- SSH access to the Batocera machine

---

## ⚡ Quick Installation via SSH

Connect to your Batocera machine via SSH and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/matt973/winwarp/main/install_winwarp.sh)
```

The installer will automatically:

1. Create the script at `/userdata/roms/ports/WinWarp.sh`
2. Download the **artwork** (`winwarp.jpg`) and **marquee** (`winwarp.png`) into `/userdata/roms/ports/images/`
3. Register WinWarp in `gamelist.xml` so it appears with media in EmulationStation
4. Set correct execution permissions
5. Verify that `efibootmgr` is available
6. Scan and detect the Windows EFI boot entry
7. Save the overlay for persistence across reboots

---

## 🎮 Usage

After installation, **WinWarp** will appear in the **Ports** section of the Batocera menu — complete with image and marquee. Simply select it and your system will:

1. Automatically detect the Windows EFI boot entry
2. Display a splash screen for 2 seconds
3. Reboot directly into Windows

On the next reboot, **Batocera resumes as the default operating system** — no changes needed.

---

## 🔁 Boot Manager Compatibility

WinWarp works with the **standard UEFI EFI boot manager** and is also fully compatible with **[rEFInd](https://www.rodsbooks.com/refind/)**.

When rEFInd is in use, WinWarp uses `efibootmgr --bootnext` to set the Windows entry as the next boot target. rEFInd respects the `BootNext` EFI variable, so the switch happens seamlessly — no rEFInd configuration required.

---

## 🔄 Update

To update WinWarp to the latest version, simply run the installation command again:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/matt973/winwarp/main/install_winwarp.sh)
```

The installer is idempotent — it safely updates the script and media without breaking your existing `gamelist.xml`.

---

## 🛠️ Manual Installation

If you prefer to install manually via SSH:

```bash
# 1. Copy the installer to Batocera
scp install_winwarp.sh root@<BATOCERA_IP>:/userdata/

# 2. Connect via SSH
ssh root@<BATOCERA_IP>

# 3. Run the installer
bash /userdata/install_winwarp.sh
```

---

## 🔍 Troubleshooting

**Windows EFI entry not found**
Run the following command to list all available EFI entries:
```bash
efibootmgr -v
```
Make sure `Windows Boot Manager` or `bootmgfw.efi` is present in the list.

**Permission error on efibootmgr**
Make sure you are running the script as root:
```bash
sudo bash /userdata/roms/ports/WinWarp.sh
```

**Script has Windows line endings (CRLF)**
If you copied the script manually on Windows, fix it with:
```bash
sed -i 's/\r//' /userdata/roms/ports/WinWarp.sh
```

**Splash screen not showing**
WinWarp tries `mpv`, `fbi`, and `fim` in order. If none are available, the reboot still proceeds normally. To install mpv on Batocera:
```bash
opkg install mpv
```

---

## 📁 Repository Structure

```
WinWarp/
├── install_winwarp.sh   # Installer — generates WinWarp.sh and downloads media
├── winwarp.jpg          # Artwork image for the Ports menu
├── winwarp.png          # Marquee logo for the Ports menu
└── LICENSE
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Retroamestation**
- GitHub: [@matt973](https://github.com/matt973)
- Shop: [retrogamestation.shop](https://retrogamestation.shop)

---

> *WinWarp — Because switching to Windows should take one click, not ten.*
