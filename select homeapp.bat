@echo off
cd "C:\android\platform-tools"
adb shell input keyevent 66
timeout /t 1 /nobreak >nul
adb shell input keyevent 20
timeout /t 1 /nobreak >nul
adb shell input keyevent 20
timeout /t 1 /nobreak >nul
adb shell input keyevent 21
timeout /t 1 /nobreak >nul
adb shell input keyevent 66