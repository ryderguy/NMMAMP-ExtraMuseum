@echo off
cd "C:\android\platform-tools"
echo Setting up launcher button 

echo Creating launch script
adb shell "echo '#!/system/bin/sh' > /data/local/tmp/launch.sh"
adb shell "echo 'while true; do' >> /data/local/tmp/launch.sh"
adb shell "echo '  getevent -lc 1 /dev/input/event2 | grep -q KEY_BACKSPACE && sleep 2 && getevent -lc 1 /dev/input/event2 | grep -q KEY_BACKSPACE && am start com.tgoodwin.emlauncher' >> /data/local/tmp/launch.sh"
adb shell "echo 'done' >> /data/local/tmp/launch.sh"

echo Making boot script
adb shell su -c "mount -o remount,rw /system && echo '#!/system/bin/sh' > /system/etc/install-recovery.sh && echo 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor' >> /system/etc/install-recovery.sh && echo 'echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq' >> /system/etc/install-recovery.sh && echo 'sh /data/local/tmp/launch.sh &' >> /system/etc/install-recovery.sh && chmod 755 /system/etc/install-recovery.sh"

echo Starting script now
adb shell "sh /data/local/tmp/launch.sh &"

echo D Hold reset for 2 seconds to open launcher
pause
