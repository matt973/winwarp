#!/bin/bash
# ============================================================
#  WinWarp - Installer rapido via SSH
#  Autore: Retroamestation
#  Repository: https://github.com/matt973/WinWarp
#  Installazione: bash <(curl -fsSL https://raw.githubusercontent.com/matt973/WinWarp/main/install_winwarp.sh)
# ============================================================

DEST="/userdata/roms/ports/WinWarp.sh"
PORTS_DIR="/userdata/roms/ports"
IMAGES_DIR="/userdata/roms/ports/images"
GAMELIST="/userdata/roms/ports/gamelist.xml"
IMAGE_PATH="/userdata/roms/ports/images/WinWarp-image.jpg"
IMAGE_URL="https://raw.githubusercontent.com/matt973/WinWarp/main/winwarp.jpg"
MARQUEE_PATH="/userdata/roms/ports/images/WinWarp-marquee.png"
MARQUEE_URL="https://raw.githubusercontent.com/matt973/WinWarp/main/winwarp.png"

echo "============================================"
echo "  WinWarp - Installazione"
echo "  github.com/matt973/WinWarp"
echo "============================================"
echo ""

# Crea le directory necessarie
for DIR in "$PORTS_DIR" "$IMAGES_DIR"; do
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR"
        echo "[OK] Directory $DIR creata."
    fi
done

# ── Download media per il menu Ports ────────────────────────
echo "Download media per il menu Ports..."

download_file() {
    local URL="$1"
    local DST="$2"
    local LABEL="$3"
    if command -v curl &>/dev/null; then
        curl -fsSL "$URL" -o "$DST"
    elif command -v wget &>/dev/null; then
        wget -q "$URL" -O "$DST"
    else
        echo "[ATTENZIONE] curl e wget non disponibili. $LABEL non scaricato."
        return 1
    fi
    if [ -f "$DST" ]; then
        echo "[OK] $LABEL scaricato in: $DST"
    else
        echo "[ATTENZIONE] Download $LABEL fallito."
    fi
}

download_file "$IMAGE_URL"   "$IMAGE_PATH"   "Image (jpg)"
download_file "$MARQUEE_URL" "$MARQUEE_PATH" "Marquee (png)"

# ── Aggiorna gamelist.xml ────────────────────────────────────
echo ""
echo "Aggiornamento gamelist.xml..."

# Crea gamelist.xml se non esiste
if [ ! -f "$GAMELIST" ]; then
    echo '<?xml version="1.0"?>' > "$GAMELIST"
    echo '<gameList>' >> "$GAMELIST"
    echo '</gameList>' >> "$GAMELIST"
    echo "[OK] gamelist.xml creato."
fi

# Aggiunge entry WinWarp solo se non già presente
if ! grep -q "WinWarp.sh" "$GAMELIST"; then
    cp "$GAMELIST" "${GAMELIST}.bak"
    echo "[OK] Backup gamelist salvato in: ${GAMELIST}.bak"
    sed -i 's|</gameList>||' "$GAMELIST"
    cat >> "$GAMELIST" << 'GAMELIST_EOF'
    <game>
        <path>./WinWarp.sh</path>
        <name>WinWarp</name>
        <desc>Riavvia rapidamente in Windows tramite EFI Boot Manager. Nessuna configurazione necessaria.</desc>
        <image>./images/WinWarp-image.jpg</image>
        <marquee>./images/WinWarp-marquee.png</marquee>
        <developer>Retroamestation</developer>
        <genre>Utility</genre>
    </game>
</gameList>
GAMELIST_EOF
    echo "[OK] Entry WinWarp aggiunta a gamelist.xml."
else
    echo "[OK] Entry WinWarp già presente in gamelist.xml."
fi

# ── Scrive lo script WinWarp principale ─────────────────────
cat > "$DEST" << 'EOF'
#!/bin/bash
# ============================================================
#  WinWarp - Boot rapido verso Windows da Linux
#  Autore: Retroamestation
#  Repository: https://github.com/matt973/WinWarp
# ============================================================

LOGO="/userdata/roms/ports/images/WinWarp-image.jpg"

# ── Rileva entry EFI Windows ─────────────────────────────────
WIN_ENTRY=$(efibootmgr -v 2>/dev/null | grep -i "bootmgfw.efi" | grep -oP 'Boot\K[0-9A-Fa-f]{4}' | head -1)

if [ -z "$WIN_ENTRY" ]; then
    WIN_ENTRY=$(efibootmgr -v 2>/dev/null | grep -i "Windows Boot Manager" | grep -oP 'Boot\K[0-9A-Fa-f]{4}' | head -1)
fi

if [ -z "$WIN_ENTRY" ]; then
    echo "ERRORE: Nessuna entry EFI di Windows trovata!"
    echo ""
    echo "Le entry disponibili sono:"
    efibootmgr -v
    sleep 8
    exit 1
fi

# Imposta BootNext
efibootmgr -n "$WIN_ENTRY" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERRORE: impossibile impostare BootNext."
    sleep 5
    exit 1
fi

# ── Mostra logo con fallback automatico ──────────────────────
show_logo() {
    local logo="$1"
    [ ! -f "$logo" ] && return

    # Metodo 1: mpv (più affidabile nell'X11 session di EmulationStation)
    if command -v mpv &>/dev/null; then
        DISPLAY=:0 XAUTHORITY=/var/lib/lxdm/lxdm.auth \
            mpv --no-audio --fullscreen --image-display-duration=2 \
            --no-osc --no-osd-bar --really-quiet "$logo" &>/dev/null &
        sleep 2
        return
    fi

    # Metodo 2: fbi (framebuffer)
    if command -v fbi &>/dev/null; then
        fbi -T 1 -d /dev/fb0 --noverbose -a "$logo" &>/dev/null &
        sleep 2
        kill %1 &>/dev/null
        return
    fi

    # Metodo 3: fim (framebuffer image viewer)
    if command -v fim &>/dev/null; then
        fim -q -a "$logo" &>/dev/null &
        sleep 2
        kill %1 &>/dev/null
        return
    fi

    # Nessun visualizzatore disponibile: attendi comunque 2s
    sleep 2
}

show_logo "$LOGO"

reboot
EOF

# Rende eseguibile
chmod +x "$DEST"
echo "[OK] Script installato in: $DEST"
echo "[OK] Permessi di esecuzione impostati."

# ── Verifica e crea shutdown.sh se mancante ──────────────────
SHUTDOWN_SCRIPT="/userdata/system/scripts/shutdown.sh"
echo ""
echo "Verifica script di sistema..."
if [ ! -f "$SHUTDOWN_SCRIPT" ]; then
    echo "[ATTENZIONE] $SHUTDOWN_SCRIPT non trovato. Creazione in corso..."
    mkdir -p /userdata/system/scripts
    cat > "$SHUTDOWN_SCRIPT" << 'SHUTDOWN_EOF'
#!/bin/bash
sleep 2
echo 1 > /proc/sys/kernel/sysrq
SHUTDOWN_EOF
    chmod +x "$SHUTDOWN_SCRIPT"
    echo "[OK] shutdown.sh creato."
else
    echo "[OK] shutdown.sh già presente."
fi

# ── Salva overlay per persistenza ────────────────────────────
batocera-save-overlay > /dev/null 2>&1 && \
    echo "[OK] Overlay salvato (persistenza garantita)." || \
    echo "[ATTENZIONE] batocera-save-overlay non disponibile."

# ── Verifica dipendenze ───────────────────────────────────────
echo ""
echo "Verifica dipendenze..."
if ! command -v efibootmgr &>/dev/null; then
    echo "[ATTENZIONE] efibootmgr non trovato. Installalo con:"
    echo "  opkg install efibootmgr"
else
    echo "[OK] efibootmgr trovato."
fi

# Segnala visualizzatore logo disponibile
for VIEWER in mpv fbi fim; do
    if command -v $VIEWER &>/dev/null; then
        echo "[OK] Visualizzatore logo: $VIEWER"
        break
    fi
done

# ── Test entry EFI ────────────────────────────────────────────
echo ""
echo "Scansione entry EFI in corso..."
WIN_TEST=$(efibootmgr -v 2>/dev/null | grep -i "bootmgfw.efi" | grep -oP 'Boot\K[0-9A-Fa-f]{4}' | head -1)
if [ -z "$WIN_TEST" ]; then
    WIN_TEST=$(efibootmgr -v 2>/dev/null | grep -i "Windows Boot Manager" | grep -oP 'Boot\K[0-9A-Fa-f]{4}' | head -1)
fi

if [ -n "$WIN_TEST" ]; then
    echo "[OK] Entry Windows rilevata: Boot${WIN_TEST}"
else
    echo "[ATTENZIONE] Nessuna entry Windows trovata su questo PC."
    echo "  Verifica con: efibootmgr -v"
fi

echo ""
echo "============================================"
echo "  Installazione completata!"
echo "  Avvia Windows dal menu Ports di Batocera"
echo "  oppure eseguendo direttamente:"
echo "  $DEST"
echo ""
echo "  Per aggiornare WinWarp in futuro:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/matt973/WinWarp/main/install_winwarp.sh)"
echo "============================================"
