#!/bin/bash
# ============================================================
#  WinWarp - Installer rapido via SSH
#  Autore: Retroamestation
#  Repository: https://github.com/matt973/WinWarp
#  Installazione: bash <(curl -fsSL https://raw.githubusercontent.com/matt973/WinWarp/main/install_winwarp.sh)
# ============================================================

DEST="/userdata/roms/ports/WinWarp.sh"
PORTS_DIR="/userdata/roms/ports"

echo "============================================"
echo "  WinWarp - Installazione"
echo "  github.com/matt973/WinWarp"
echo "============================================"
echo ""

# Crea la directory ports se non esiste
if [ ! -d "$PORTS_DIR" ]; then
    mkdir -p "$PORTS_DIR"
    echo "[OK] Directory $PORTS_DIR creata."
fi

# Scrive lo script WinWarp
cat > "$DEST" << 'EOF'
#!/bin/bash
# ============================================================
#  WinWarp - Boot rapido verso Windows da Linux
#  Autore: Retroamestation
#  Repository: https://github.com/matt973/WinWarp
# ============================================================

LOGO="/userdata/themes/retrogamestation/_inc/assets/background.png"

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

efibootmgr -n "$WIN_ENTRY" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERRORE: impossibile impostare BootNext."
    sleep 5
    exit 1
fi

# Mostra il logo a schermo intero per 2 secondi
if [ -f "$LOGO" ]; then
    if command -v fbi &>/dev/null; then
        fbi -T 1 -d /dev/fb0 --noverbose -a "$LOGO" &>/dev/null &
    elif command -v fim &>/dev/null; then
        fim -q -a "$LOGO" &>/dev/null &
    fi
fi

sleep 2
reboot
EOF

# Rende eseguibile
chmod +x "$DEST"
echo "[OK] Script installato in: $DEST"
echo "[OK] Permessi di esecuzione impostati."

# Verifica e crea shutdown.sh se mancante
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

# Salva overlay per persistenza
batocera-save-overlay > /dev/null 2>&1 && echo "[OK] Overlay salvato (persistenza garantita)." || echo "[ATTENZIONE] batocera-save-overlay non disponibile."

# Verifica efibootmgr
echo ""
echo "Verifica dipendenze..."
if ! command -v efibootmgr &>/dev/null; then
    echo "[ATTENZIONE] efibootmgr non trovato. Installalo con:"
    echo "  opkg install efibootmgr"
else
    echo "[OK] efibootmgr trovato."
fi

# Test immediato: cerca entry Windows
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
echo "  Puoi avviare Windows dal menu Ports"
echo "  di Batocera oppure eseguendo:"
echo "  $DEST"
echo ""
echo "  Per aggiornare WinWarp:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/matt973/WinWarp/main/install_winwarp.sh)"
echo "============================================"
