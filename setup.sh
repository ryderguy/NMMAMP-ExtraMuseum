#!/bin/bash
# ==============================================================================
# Namco Museum My Arcade Mini Player - Linux Deployment Master Tool (ExtraMuseum) 
# Ported from the original Windows .bat scripts by Terry Goodwin (v1) / ryderguy (v2)
# Modded with Dual-Boot Linux Server Subsystems and Direct High-Speed Backups (high speed depending on cable)
# also put way more time into linux port thats why it hasnt been updated in 4 months
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
THIS_PATH="$(pwd)"
if ! command -v adb &> /dev/null; then
    echo -e "${RED}[ERROR] ADB is not installed on this system.${NC}"
    echo "Install it via your package manager (e.g., sudo apt install adb, sudo pacman -S android-tools)"
    exit 1
fi
show_menu() {
    clear
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}   Namco Museum Mini Player - Extra Museum (Linux Port)${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e " 1)  ${YELLOW}Full Install${NC} (run_me_first_after_readme)"
    echo -e " 2)  ${YELLOW}Get Root / Remount${NC} (root)"
    echo -e " 3)  ${YELLOW}Overclock CPU to 1248MHz (persistent)${NC} (overclock)"
    echo -e " 4)  ${YELLOW}Reset Button Setup - KEEP OVERCLOCK${NC} (resetbuttonsetup)"
    echo -e " 5)  ${YELLOW}Reset Button Setup - NO OVERCLOCK${NC}"
    echo -e " 6)  ${YELLOW}Install Launcher APK Only${NC} (install_launcher)"
    echo -e " 7)  ${YELLOW}Install RetroArch Only${NC} (install_retroarch)"
    echo -e " 8)  ${YELLOW}Install ROMs, BIOS & Cores${NC} (High Capacity SDCard Layout)"
    echo -e " 9)  ${YELLOW}Extract Stock ROMs from Device${NC}"
    echo -e " 10) ${YELLOW}Fix Stuck Home Launcher Popup${NC} (select homeapp)"
    echo -e " 11) ${RED}Remove Everything (restore to stock)${NC} (remove_all)"
    echo -e " 12) ${RED}Remove All RetroArch Data${NC} (cores/playlists/thumbnails)"
    echo -e " 13) ${RED}Remove All ROMs${NC} (remove_roms)"
    echo -e " 14) ${GREEN}Pull Complete OS Firmware Backup Image${NC} (High-Speed Direct Mode)"
    echo -e " 15) ${GREEN}Boot Into Headless Linux Server OS${NC} (Dual-Boot / Chroot)"
    echo -e " 16) ${GREEN}Share PC Internet Over USB${NC} (reverse-tether to device)"
    echo -e " q)  Exit"
    echo -e "${BLUE}======================================================${NC}"
    echo -n "Select an option [1-16 or q]: "
}
check_device() {
    if ! adb get-state &>/dev/null; then
        echo -e "${RED}[ERROR] No ADB device detected. Connect the device and enable USB debugging.${NC}"
        read -p "Press Enter to return to menu..."
        return 1
    fi
    return 0
}
confirm_yes() {
    case "$1" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}
do_root() {
    echo -e "\n${BLUE}[*] Getting devices with ADB...${NC}"
    adb devices
    echo -e "\n${BLUE}[*] Getting root access for various protected actions...${NC}"
    adb root || { echo -e "${RED}Failed to get root status.${NC}"; return; }
    echo -e "\n${BLUE}[*] Remounting the file system so we can write to protected areas...${NC}"
    adb remount || { echo -e "${RED}Failed to remount filesystem...${NC}"; return; }
    echo -e "${GREEN}[+] Root + remount complete.${NC}"
}
do_overclock() {
    echo -e "\n${BLUE}[*] Setting up overclock...${NC}"
    adb shell su -c "mount -o remount,rw /system"
    adb shell su -c "echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    adb shell su -c "echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
    adb shell su -c "echo '#!/system/bin/sh' > /system/etc/install-recovery.sh"
    adb shell su -c "echo 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor' >> /system/etc/install-recovery.sh"
    adb shell su -c "echo 'echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq' >> /system/etc/install-recovery.sh"
    adb shell su -c "chmod 755 /system/etc/install-recovery.sh"
    echo -e "${GREEN}[+] Overclocked to 1248MHz (was ~254MHz stock). This persists across reboots.${NC}"
}
do_reset_button_setup() {
    local keep_overclock="$1"
    echo -e "\n${BLUE}[*] Setting up launcher button${NC}"
    adb shell "echo '#!/system/bin/sh' > /data/local/tmp/launch.sh"
    adb shell "echo 'while true; do' >> /data/local/tmp/launch.sh"
    adb shell "echo '  getevent -lc 1 /dev/input/event2 | grep -q KEY_BACKSPACE && sleep 2 && getevent -lc 1 /dev/input/event2 | grep -q KEY_BACKSPACE && am start com.tgoodwin.emlauncher' >> /data/local/tmp/launch.sh"
    adb shell "echo 'done' >> /data/local/tmp/launch.sh"
    if [[ "$keep_overclock" == "1" ]]; then
        adb shell su -c "mount -o remount,rw /system && echo '#!/system/bin/sh' > /system/etc/install-recovery.sh && echo 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor' >> /system/etc/install-recovery.sh && echo 'echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq' >> /system/etc/install-recovery.sh && echo 'sh /data/local/tmp/launch.sh &' >> /system/etc/install-recovery.sh && chmod 755 /system/etc/install-recovery.sh"
    else
        adb shell su -c "mount -o remount,rw /system && echo '#!/system/bin/sh' > /system/etc/install-recovery.sh && echo 'sh /data/local/tmp/launch.sh &' >> /system/etc/install-recovery.sh && chmod 755 /system/etc/install-recovery.sh"
    fi
    adb shell "sh /data/local/tmp/launch.sh &"
    echo -e "${GREEN}[+] Reset button mapped.${NC}"
}
do_install_launcher() {
    echo -e "\n${BLUE}[*] Installing emlauncher.apk...${NC}"
    adb install "$THIS_PATH/frontend/emlauncher.apk" || { echo -e "${RED}Failed to install launcher APK.${NC}"; return; }
    echo -e "${GREEN}[+] Success - emlauncher.apk installed.${NC}"
}
do_install_retroarch() {
    echo -e "\n${BLUE}[*] Installing RetroArch APK...${NC}"
    adb install "$THIS_PATH/retroarch/retroarch.apk" || { echo -e "${RED}Failed to install RetroArch APK.${NC}"; return; }
    echo -e "\n${BLUE}[*] Initializing first launch profile configurations...${NC}"
    adb push "$THIS_PATH/retroarch/retroarch.cfg" /data/data/com.retroarch/files/retroarch.cfg || { echo -e "${RED}Failed to push retroarch.cfg layout config.${NC}"; return; }
    echo -e "${GREEN}[+] Configuration bindings pushed successfully.${NC}"
}
do_install_roms() {
    echo -e "\n${BLUE}[*] Initializing High-Capacity Emulation Deployment Matrix...${NC}"
    adb shell "mkdir -p /sdcard/ExtraMuseum/roms"
    adb shell "mkdir -p /sdcard/ExtraMuseum/bios"
    if [ -d "$THIS_PATH/roms" ]; then
        echo "Pushing ROMs to /sdcard/ExtraMuseum/roms/..."
        adb push "$THIS_PATH/roms/" /sdcard/ExtraMuseum/roms/
    fi
    if [ -d "$THIS_PATH/bios" ]; then
        echo "Pushing BIOS profiles to /sdcard/ExtraMuseum/bios/..."
        adb push "$THIS_PATH/bios/" /sdcard/ExtraMuseum/bios/
    fi
    if [ -d "$THIS_PATH/frontend" ]; then
        adb push "$THIS_PATH/frontend/gamelist.json" /data/local/tmp/gamelist.json
        adb push "$THIS_PATH/frontend/screenshots/" /data/local/tmp/screenshots/ 2>/dev/null
        adb push "$THIS_PATH/frontend/systems/" /data/local/tmp/systems/ 2>/dev/null
        adb push "$THIS_PATH/frontend/thumbnails/" /data/local/tmp/thumbnails/ 2>/dev/null
    fi
    if [ -d "$THIS_PATH/retroarch/config" ]; then
        adb push "$THIS_PATH/retroarch/config/" /data/data/com.retroarch/files/config/
    fi
    if [ -d "$THIS_PATH/retroarch/cores" ]; then
        adb push "$THIS_PATH/retroarch/cores/" /data/data/com.retroarch/files/cores/
    fi
    echo -e "${GREEN}[+] Data sync complete! 1.8GB space partition is utilized.${NC}"
}
do_extract_stock_roms() {
    echo -e "\n${BLUE}[*] Extracting internal arcade assets to local computer...${NC}"
    mkdir -p "$THIS_PATH/stock_extracted_dump"
    adb pull /GAME/ "$THIS_PATH/stock_extracted_dump/" || { echo -e "${RED}Failed to pull /GAME/ partition.${NC}"; return; }
    echo -e "${GREEN}[+] Factory configurations pulled into stock_extracted_dump/${NC}"
}

# ------------------------------------------------------------------
# select homeapp.bat - real fix. This is a keyevent sequence that
# navigates the stuck "Just once / Always" default-app chooser
# dialog and confirms a selection: Enter, Down, Down, Left, Enter.
# The previous pm-enable/HOME-intent version didn't actually
# interact with the dialog at all.
# ------------------------------------------------------------------
do_fix_home_launcher() {
    echo -e "\n${BLUE}[*] Sending keyevent sequence to dismiss stuck launcher popup...${NC}"
    adb shell input keyevent 66   # Enter
    sleep 1
    adb shell input keyevent 20   # Down
    sleep 1
    adb shell input keyevent 20   # Down
    sleep 1
    adb shell input keyevent 21   # Left
    sleep 1
    adb shell input keyevent 66   # Enter
    echo -e "${GREEN}[+] Done. If the popup is still stuck, try running this again or a second time in a row.${NC}"
}

do_remove_all() {
    echo -e "\n${RED}[WARNING] You are about to clear all mods and restore factory limits!${NC}"
    echo -n "Are you completely sure? (y/N): "
    read -r confirm
    if ! confirm_yes "$confirm"; then return; fi
    adb uninstall com.retroarch
    adb uninstall com.tgoodwin.emlauncher
    adb uninstall com.ryderguy.emlauncher
    adb shell "rm -rf /data/local/tmp/roms"
    adb shell "rm -rf /data/local/tmp/bios"
    adb shell "rm -rf /data/local/tmp/launch.sh"
    adb shell "rm -rf /sdcard/ExtraMuseum"
    adb shell su -c "mount -o remount,rw /system && rm -f /system/etc/install-recovery.sh"
    echo -e "${GREEN}[+] System clean! Restart your cabinet to complete the factory restoration.${NC}"
}
do_remove_retroarch_data() {
    adb shell "rm -rf /data/data/com.retroarch/files/config"
    adb shell "rm -rf /data/data/com.retroarch/files/cores"
    adb shell "rm -rf /data/data/com.retroarch/files/playlists"
    adb shell "rm -rf /data/data/com.retroarch/files/thumbnails"
    echo -e "${GREEN}[+] RetroArch directory blocks purged successfully.${NC}"
}
do_remove_roms() {
    adb shell "rm -rf /data/local/tmp/roms"
    adb shell "rm -rf /sdcard/ExtraMuseum"
    echo -e "${GREEN}[+] ROM directories clean.${NC}"
}
do_full_install() {
    do_root
    do_overclock
    do_install_retroarch
    do_install_launcher
    do_install_roms
    do_reset_button_setup "1"
    echo -e "\n${GREEN}[=== ALL DEPLOYMENT ARRAYS COMPLETED SUCCESSFULY ===]${NC}"
}

# ------------------------------------------------------------------
# Real USB reverse-tether: shares this PC's internet connection with
# the device over the same USB cable used for ADB. Requires the
# device to expose a USB network interface (usb0/rndis0) when
# plugged in - most rooted Android devices do this automatically,
# but you may need to enable "USB tethering" or a similar option in
# the device's network settings first, or it may need a kernel
# module (g_ether/rndis) loaded on the device side.
#
# Cleans up iptables/forwarding rules on exit so it doesn't leave
# your host's network config in a weird state.
# ------------------------------------------------------------------
PC_NET_IFACE=""
USB_NET_IFACE=""
cleanup_usb_internet() {
    if [[ -n "$PC_NET_IFACE" && -n "$USB_NET_IFACE" ]]; then
        echo -e "\n${YELLOW}[*] Cleaning up USB internet-sharing rules...${NC}"
        sudo iptables -t nat -D POSTROUTING -o "$PC_NET_IFACE" -j MASQUERADE 2>/dev/null
        sudo iptables -D FORWARD -i "$PC_NET_IFACE" -o "$USB_NET_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null
        sudo iptables -D FORWARD -i "$USB_NET_IFACE" -o "$PC_NET_IFACE" -j ACCEPT 2>/dev/null
        sudo ip addr del 192.168.42.1/24 dev "$USB_NET_IFACE" 2>/dev/null
        sudo ip link set "$USB_NET_IFACE" down 2>/dev/null
        PC_NET_IFACE=""
        USB_NET_IFACE=""
    fi
}
trap cleanup_usb_internet EXIT

do_share_internet() {
    echo -e "\n${BLUE}[*] Available network interfaces on this PC:${NC}"
    ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$'
    echo ""
    echo -e "${YELLOW}Note: modern Linux doesn't use 'usb0' naming - the device's USB link${NC}"
    echo -e "${YELLOW}will usually show up as something like enpXsYfZuW (the 'u' = USB port).${NC}"
    echo ""
    read -p "Enter the interface providing your INTERNET connection (e.g. wlan0, enp1s0): " pc_net
    read -p "Enter the interface connected to the ARCADE DEVICE (e.g. enp0s20f0u3): " usb_net
    if [[ -z "$pc_net" || -z "$usb_net" ]]; then
        echo -e "${RED}Both interfaces are required, aborting.${NC}"
        return
    fi
    PC_NET_IFACE="$pc_net"
    USB_NET_IFACE="$usb_net"

    echo -e "\n${BLUE}[*] Enabling IP forwarding on this PC...${NC}"
    sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null

    echo -e "${BLUE}[*] Bringing up $USB_NET_IFACE on this PC (192.168.42.1/24)...${NC}"
    sudo ip link set "$USB_NET_IFACE" up || { echo -e "${RED}Couldn't bring up $USB_NET_IFACE - check the interface name with 'ip link' and try again.${NC}"; PC_NET_IFACE=""; USB_NET_IFACE=""; return; }
    if ! sudo ip addr add 192.168.42.1/24 dev "$USB_NET_IFACE" 2>/dev/null; then
        echo -e "${YELLOW}Could not add address (may already be set, continuing)...${NC}"
    fi

    echo -e "${BLUE}[*] Setting up NAT so the device can reach the internet through $pc_net...${NC}"
    sudo iptables -t nat -A POSTROUTING -o "$pc_net" -j MASQUERADE
    sudo iptables -A FORWARD -i "$pc_net" -o "$USB_NET_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i "$USB_NET_IFACE" -o "$pc_net" -j ACCEPT

    echo -e "${BLUE}[*] Configuring the device's network side over ADB...${NC}"
    echo -e "${YELLOW}Note: the device-side interface name may also differ (rndis0, usb0, eth0, etc).${NC}"
    read -p "Enter the network interface name AS SEEN ON THE DEVICE (default: rndis0): " device_iface
    device_iface="${device_iface:-rndis0}"
    adb shell su -c "ip addr add 192.168.42.2/24 dev $device_iface" 2>/dev/null
    adb shell su -c "ip link set $device_iface up" 2>/dev/null
    adb shell su -c "ip route add default via 192.168.42.1 dev $device_iface" 2>/dev/null
    adb shell su -c "setprop net.dns1 8.8.8.8" 2>/dev/null

    echo -e "\n${YELLOW}[*] Testing connectivity from the device...${NC}"
    adb shell su -c "ping -c 3 8.8.8.8"

    echo -e "\n${GREEN}[+] Internet bridge is up (or see above if the ping failed). The device should now have internet through this PC.${NC}"
    read -p "Press Enter when you're done, to tear the bridge back down..."
    cleanup_usb_internet
    echo -e "${GREEN}[+] Bridge torn down, PC network settings restored.${NC}"
}

# ==============================================================================
# Main Program Navigation Processing Engine Loop
while true; do
    show_menu
    read -r choice
    case "$choice" in
        1)  check_device && do_full_install ;;
        2)  check_device && do_root ;;
        3)  check_device && do_overclock ;;
        4)  check_device && do_reset_button_setup "1" ;;
        5)  check_device && do_reset_button_setup "0" ;;
        6)  check_device && do_install_launcher ;;
        7)  check_device && do_install_retroarch ;;
        8)  check_device && do_install_roms ;;
        9)  check_device && do_extract_stock_roms ;;
        10) check_device && do_fix_home_launcher ;;
        11) check_device && do_remove_all ;;
        12) check_device && do_remove_retroarch_data ;;
        13) check_device && do_remove_roms ;;
        
        14)
            check_device || continue
            echo -e "\n${BLUE}[*] Initializing High-Speed Direct Root OS Backup...${NC}"
            mkdir -p "$THIS_PATH/firmware_backups"
            
            echo -e "${YELLOW}[1/2] Unlocking internal system clearance flags...${NC}"
            adb root > /dev/null 2>&1
            sleep 2
            
            echo -e "${YELLOW}[2/2] Streaming raw OS partition (actc) directly to computer...${NC}"
            adb pull /dev/block/actc "$THIS_PATH/firmware_backups/namco_stock_system.img"
            
            if [ -s "$THIS_PATH/firmware_backups/namco_stock_system.img" ]; then
                echo -e "\n${GREEN}[SUCCESS] Complete factory system partition clone safely saved!${NC}"
                echo "Target Location: $THIS_PATH/firmware_backups/namco_stock_system.img"
            else
                echo -e "\n${RED}[ERROR] Streaming array pipeline terminated incorrectly.${NC}"
            fi
            read -p "Press Enter to return to main menu..."
            ;;
                15)
            check_device || continue
            echo -e "\n${BLUE}[*] Checking Framework for Headless Dual-Boot Linux Server...${NC}"
            LINUX_DIR="/data/local/ubuntu"
            
            # Elevate connection to root access
            adb root >/dev/null 2>&1
            sleep 1
            
            # Check if a filesystem already exists inside the cabinet memory layout
            IF_EXISTS=$(adb shell "if [ -d '$LINUX_DIR/bin' ]; then echo 'YES'; fi")
            
            if [ "$IF_EXISTS" != "YES" ]; then
                echo -e "${YELLOW}[!] Linux root filesystem not detected inside cabinet internal memory.${NC}"
                echo -e "${BLUE}Scanning workspace directory for any available ARMhf rootfs archives...${NC}"
                
                # Check for any available compressed archive files in the local workspace path
                shopt -s nullglob
                archives=( *.tar.gz )
                shopt -u nullglob
                
                if [ ${#archives[@]} -eq 0 ]; then
                    echo -e "${RED}[ERROR] No .tar.gz archive files found in your local project folder!${NC}"
                    echo "Please drop your preferred custom OS tarball layout into this directory first."
                    read -p "Press Enter to return to menu..."
                    continue
                fi
                
                echo -e "\n${YELLOW}Available Operating System Archives Found:${NC}"
                for i in "${!archives[@]}"; do
                    echo -e "  $((i+1))) ${GREEN}${archives[$i]}${NC}"
                done
                echo ""
                
                echo -n "Select an archive number, or manually type a filename: "
                read -r user_selection
                
                SELECTED_OS_FILE=""
                # Determine if the user input a selection index number or a direct literal file path
                if [[ "$user_selection" =~ ^[0-9]+$ ]] && [ "$user_selection" -ge 1 ] && [ "$user_selection" -le "${#archives[@]}" ]; then
                    SELECTED_OS_FILE="${archives[$((user_selection-1))]}"
                else
                    SELECTED_OS_FILE="$user_selection"
                fi
                
                if [ ! -f "$THIS_PATH/$SELECTED_OS_FILE" ]; then
                    echo -e "${RED}[ERROR] Target file '$THIS_PATH/$SELECTED_OS_FILE' does not exist!${NC}"
                    read -p "Press Enter to return to menu..."
                    continue
                fi
                
                echo -e "\n${GREEN}[✓] Selected Target OS: $SELECTED_OS_FILE${NC}"
                
                # Step A: Create a temporary extraction workspace folder on your Linux PC
                echo -e "${BLUE}[*] Extracting $SELECTED_OS_FILE locally on your PC to bypass missing cabinet tar tool...${NC}"
                mkdir -p "$THIS_PATH/temp_extracted_linux"
                sudo tar -xzf "$THIS_PATH/$SELECTED_OS_FILE" -C "$THIS_PATH/temp_extracted_linux/"
                
                # Step B: Push the pre-extracted files straight onto the cabinet's 1.8GB partition
                echo -e "${BLUE}[*] Streaming extracted Linux rootfs structure to the 1.8GB partition... (Please wait)${NC}"
                adb shell "su -c 'mkdir -p $LINUX_DIR'"
                sudo adb push "$THIS_PATH/temp_extracted_linux/." "$LINUX_DIR/"
                
                # Clean up local PC workspace folder
                sudo rm -rf "$THIS_PATH/temp_extracted_linux"
                echo -e "${GREEN}[+] Direct partition extraction complete!${NC}"
            fi
            
            echo -e "${BLUE}[*] Bridging native hardware allocation channels over the USB bus...${NC}"
            # Use legacy mounting flags to ensure Android 4.4 compatibility paths are parsed correctly
            adb shell "su -c 'mount -t proc proc $LINUX_DIR/proc'" 2>/dev/null
            adb shell "su -c 'mount -t sysfs sysfs $LINUX_DIR/sys'" 2>/dev/null
            adb shell "su -c 'mount -o bind /dev $LINUX_DIR/dev'" 2>/dev/null
            
            # Configure network name resolution targets inside the open Linux file layout
            adb shell "su -c 'echo \"nameserver 8.8.8.8\" > $LINUX_DIR/etc/resolv.conf'"
            
            echo -e "\n${GREEN}[SUCCESS] Switched environments! Entering Headless Linux Core Shell...${NC}"
            echo -e "${BLUE}================================================================${NC}"
            echo " Every command typed here runs natively on the arcade hardware working internet also can work here "
            echo " Type 'exit' to shut down Linux and return to your PC prompt."
            echo -e "${BLUE}================================================================${NC}"
            
            # Fall back through busybox environment arrays if standard chroot flags throw errors
            adb shell "su -c 'busybox chroot $LINUX_DIR /bin/bash --login'" || adb shell "su -c 'chroot $LINUX_DIR /bin/bash --login'"
            
            echo -e "\n${RED}[*] Exited Linux. Safely tearing down hardware bridging loops...${NC}"
            adb shell "su -c 'umount $LINUX_DIR/proc'" 2>/dev/null
            adb shell "su -c 'umount $LINUX_DIR/sys'" 2>/dev/null
            adb shell "su -c 'umount $LINUX_DIR/dev'" 2>/dev/null
            echo -e "${GREEN}[+] Android environment safely restored to focus.${NC}"
            read -p "Press Enter to return to main menu..."
            ;;
        16) check_device && do_share_internet ;;
        q|Q)
            echo -e "\nThanks for using my script/repo.\n"
            exit 0
            ;;
            
        *)
            echo -e "\n${RED}[!] Invalid choice selection.${NC}"
            sleep 1.5
            ;;
    esac
    echo ""
done
