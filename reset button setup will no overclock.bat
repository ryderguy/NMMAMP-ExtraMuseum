@echo off
cd "C:\android\platform-tools"
echo Setting up launcher button

echo Creating launch script
adb shell "echo '#!/system/bin/sh' > /data/local/tmp/launch.sh"
adb shell "echo 'while true; do' >> /data/local/tmp/launch.sh"
adb shell "echo '  getevent -lc 1 /dev/input/event2 | grep -q KEY_BACKSPACE && sleep 2 && getevent -lc 1 /dev/input/event2 | grep -q KEY_BACKSPACE && am start com.tgoodwin.emlauncher' >> /data/local/tmp/launch.sh"
adb shell "echo 'done' >> /data/local/tmp/launch.sh"

echo Making boot script
adb shell su -c "mount -o remount,rw /system"
adb shell su -c "echo '#!/system/bin/sh' > /system/etc/install-recovery.sh"
adb shell su -c "echo 'sh /data/local/tmp/launch.sh &' >> /system/etc/install-recovery.sh"
adb shell su -c "chmod 755 /system/etc/install-recovery.sh"

echo Starting script now...
adb shell "sh /data/local/tmp/launch.sh &"

echo Hold reset for 2 seconds to open launcher
pause
