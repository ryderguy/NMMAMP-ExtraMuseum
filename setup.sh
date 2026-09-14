#!/bin/bash
# ==============================================================================
# Namco Museum My Arcade Mini Player
#this is just a port from the bat files nothing that different
# 
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
    echo -e "${GREEN}   Namco Museum Mini Player (Linux Port)${NC}"
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
    echo -e " q)  Exit"
    echo -e "${BLUE}======================================================${NC}"
    echo -n "Select an option [1-16 or q]: "
}
check_device() {
    if ! adb get-state &>/dev/null; then
        echo -e "${RED}[ERROR] No ADB device detected Connect the device and enable USB debugging.${NC}"
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
            
      
            adb root >/dev/null 2>&1
            sleep 1
            
            IF_EXISTS=$(adb shell "if [ -d '$LINUX_DIR/bin' ]; then echo 'YES'; fi")
            
            if [ "$IF_EXISTS" != "YES" ]; then
                echo -e "${YELLOW}[!] Linux root filesystem not detected inside cabinet internal memory.${NC}"
                echo -e "${BLUE}Scanning workspace directory for any available ARMhf rootfs archives...${NC}"
                
             
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
                
            
                echo -e "${BLUE}[*] Extracting $SELECTED_OS_FILE locally on your PC to bypass missing cabinet tar tool...${NC}"
                mkdir -p "$THIS_PATH/temp_extracted_linux"
                sudo tar -xzf "$THIS_PATH/$SELECTED_OS_FILE" -C "$THIS_PATH/temp_extracted_linux/"
                
           
                echo -e "${BLUE}[*] Streaming extracted Linux rootfs structure to the 1.8GB partition... (Please wait)${NC}"
                adb shell "su -c 'mkdir -p $LINUX_DIR'"
                sudo adb push "$THIS_PATH/temp_extracted_linux/." "$LINUX_DIR/"
                
             
                sudo rm -rf "$THIS_PATH/temp_extracted_linux"
                echo -e "${GREEN}[+] Direct partition extraction complete!${NC}"
            fi
            
            echo -e "${BLUE}[*] Bridging native hardware allocation channels over the USB bus...${NC}"
        
            adb shell "su -c 'mount -t proc proc $LINUX_DIR/proc'" 2>/dev/null
            adb shell "su -c 'mount -t sysfs sysfs $LINUX_DIR/sys'" 2>/dev/null
            adb shell "su -c 'mount -o bind /dev $LINUX_DIR/dev'" 2>/dev/null
            
         
            adb shell "su -c 'echo \"nameserver 8.8.8.8\" > $LINUX_DIR/etc/resolv.conf'"
            
            echo -e "\n${GREEN}[SUCCESS] Switched environments! Entering Headless Linux Core Shell...${NC}"
            echo -e "${BLUE}================================================================${NC}"
            echo " Every command typed here runs natively on the arcade hardware working internet also can work here "
            echo " Type 'exit' to shut down Linux and return to your PC prompt."
            echo -e "${BLUE}================================================================${NC}"
            
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
