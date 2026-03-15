@echo off
cd "C:\android\platform-tools"
echo Setting up overclock...
adb shell su -c "mount -o remount,rw /system"
adb shell su -c "echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
adb shell su -c "echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
adb shell su -c "echo '#!/system/bin/sh' > /system/etc/install-recovery.sh"
adb shell su -c "echo 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor' >> /system/etc/install-recovery.sh"
adb shell su -c "echo 'echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq' >> /system/etc/install-recovery.sh"
adb shell su -c "chmod 755 /system/etc/install-recovery.sh"
echo overclocked to 1240mhz it used to be at 254 i think and this will stay overclocked
pause