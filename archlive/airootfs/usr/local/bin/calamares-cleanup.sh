#!/usr/bin/env bash
# Post-installation cleanup script executed inside the target system chroot by Calamares

set -e

echo "=== UniOS Post-Install Cleanup Starting ==="

# 1. Remove live autologin configurations so the installed system boots cleanly to the display manager
echo "--> Removing live autologin configurations..."
rm -f /etc/sddm.conf.d/autologin.conf
rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
rmdir --ignore-fail-on-non-empty /etc/systemd/system/getty@tty1.service.d 2>/dev/null || true

# 2. Remove live Calamares autostart and launcher scripts
echo "--> Removing Calamares autostart and live launchers..."
rm -f /etc/xdg/autostart/calamares.desktop
rm -f /usr/local/bin/calamares-launcher
rm -f /usr/share/applications/calamares.desktop 2>/dev/null || true
rm -f /usr/share/applications/io.calamares.calamares.desktop 2>/dev/null || true

# 3. Remove liveuser account, home directory, and live privileges
echo "--> Cleaning up liveuser account and live-specific permissions..."
if id "liveuser" &>/dev/null; then
    userdel -r -f liveuser 2>/dev/null || true
fi
rm -rf /home/liveuser
rm -f /etc/sudoers.d/liveuser
rm -f /etc/polkit-1/rules.d/49-nopasswd_global.rules

# 4. Remove live-only scripts and tools
echo "--> Removing live-only scripts..."
rm -f /root/.automated_script.sh
rm -f /usr/local/bin/choose-mirror
rm -f /usr/local/bin/Installation_guide
rm -f /usr/local/bin/livecd-sound
rm -rf /usr/local/share/livecd-sound

# 5. Disable and remove live-only systemd services
echo "--> Disabling live-only systemd services..."
LIVE_SERVICES=(
    choose-mirror.service
    livecd-talk.service
    livecd-alsa-unmuter.service
    pacman-init.service
    etc-pacman.d-gnupg.mount
    cloud-init-local.service
    cloud-init-main.service
    cloud-init-network.service
    cloud-config.service
    cloud-final.service
)

for s in "${LIVE_SERVICES[@]}"; do
    rm -f "/etc/systemd/system/$s"
    rm -f "/etc/systemd/system/multi-user.target.wants/$s"
    rm -f "/etc/systemd/system/sound.target.wants/$s"
    rm -f "/etc/systemd/system/cloud-init.target.wants/$s"
done
rm -rf /etc/systemd/system/cloud-init.target.wants 2>/dev/null || true

# 6. Remove installer packages from target system
echo "--> Removing installer and live packages from installed system..."
pacman -Rsn --noconfirm unios-calamares 2>/dev/null || true
pacman -Rsn --noconfirm ckbcomp 2>/dev/null || true
pacman -Rsn --noconfirm mkinitcpio-archiso 2>/dev/null || true

# 7. Clean package caches and delete self
echo "--> Cleaning package cache..."
pacman -Scc --noconfirm 2>/dev/null || true

echo "=== UniOS Post-Install Cleanup Complete ==="
rm -f /usr/local/bin/calamares-cleanup.sh
