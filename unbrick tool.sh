#!/bin/bash
# ==============================================================================
# NMMAMP-ExtraMuseum - Automated Hardware Rescue & Unbricker Utility
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}   ExtraMuseum - Actions GS705B System Rescue Tool     ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo " Waiting for the arcade cabinet to be connected over USB..."
echo " (If the device is bootlooping, keep it plugged into your PC)"
echo "------------------------------------------------------"

# Infinite monitoring loop looking for the exact hardware signatures you discovered
while true; do
    # Scan USB nodes for normal tablet mode, recovery mode, or ADFU bootloader state
    USB_STATUS=$(lsusb | grep -E "10d6:0c02|10d6:0c01|10d6:10d6|10d6:8888")
    
    if [ -n "$USB_STATUS" ]; then
        echo -e "\n${GREEN}[+] Device Detected on USB Bus!${NC}"
        echo -e "Hardware String: $USB_STATUS\n"
        break
    fi
    sleep 1
done

# Step 2: Determine what state the hardware is sitting in
if echo "$USB_STATUS" | grep -q "0c02"; then
    echo -e "${YELLOW}[STATE] Cabinet is booted in normal Tablet Mode (10d6:0c02).${NC}"
    echo "Attempting to gain root ADB access to clear the crash loops..."
    
    adb wait-for-device
    adb root && adb remount
    
    echo -e "\n${BLUE}[*] Forcefully stripping out broken configurations...${NC}"
    # Force the package manager to unblock the custom launcher interface
    adb shell "su -c 'pm enable com.ryderguy.emlauncher'" 2>/dev/null
    adb shell "su -c 'pm enable com.tgoodwin.emlauncher'" 2>/dev/null
    
    echo -e "${BLUE}[*] Restoring standard Android default activity targets...${NC}"
    adb shell "su -c 'am start -n com.ryderguy.emlauncher/.MainActivity'" 2>/dev/null
    
elif echo "$USB_STATUS" | grep -q "0c01"; then
    echo -e "${RED}[STATE] Cabinet is stuck in Android Recovery Mode (10d6:0c01).${NC}"
    echo "The standard operating system is currently offline."
    echo "Attempting to push factory recovery repair scripts..."
    
    if adb devices | grep -q "recovery"; then
        echo -e "${GREEN}[+] Recovery communication channel is OPEN.${NC}"
        # Wipes the broken data/cache folders that cause boot loops
        adb shell "recovery --wipe_data" 2>/dev/null
        echo -e "${GREEN}[+] Factory format instruction sent. The unit should reboot cleanly.${NC}"
    else
        echo -e "${RED}[ERROR] Recovery channel locked. Unplug the cable and hold joystick DOWN while inserting.${NC}"
    fi

else
    echo -e "${RED}[STATE] Cabinet is sitting in low-level ADFU Bootloader Mode.${NC}"
    echo "The processor is waiting for raw custom .fw image binary flashing."
    echo "Please launch the Actions Pad Product Tool to rewrite the partition blocks."
fi

echo -e "\n------------------------------------------------------"
echo -e "${GREEN}[SUCCESS] Rescue sequence operation completed.${NC}"
echo -e "------------------------------------------------------"
