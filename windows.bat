@echo off
echo ===========================================================
echo             VM WINDOWS SETUP SCRIPT
echo ===========================================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Script phai chay voi quyen Administrator!
    echo Hay click chuot phai vao file va chon "Run as administrator"
    pause
    exit /b 1
)

echo [INFO] Dang thiet lap VM Windows...
echo.

REM 1. Set timezone to GMT+7 (SE Asia Standard Time)
echo [1/5] Dang thiet lap timezone GMT+7...
tzutil /s "SE Asia Standard Time"
if %errorLevel% equ 0 (
    echo [OK] Da thiet lap timezone thanh cong
) else (
    echo [ERROR] Khong the thiet lap timezone
)
echo.

REM 2. Enable Remote Desktop
echo [2/5] Dang kich hoat Remote Desktop...
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f >nul

REM Enable Remote Desktop firewall rules
netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Da kich hoat Remote Desktop thanh cong
) else (
    echo [ERROR] Co loi khi kich hoat Remote Desktop
)
echo.

REM 3. Enable ICMP (ping) firewall rules
echo [3/5] Dang kich hoat Firewall Rule cho ping...
netsh advfirewall firewall add rule name="Allow ICMP IPv4" protocol=icmpv4:8,any dir=in action=allow >nul 2>&1
netsh advfirewall firewall add rule name="Allow ICMP IPv6" protocol=icmpv6:128,any dir=in action=allow >nul 2>&1
netsh advfirewall firewall set rule name="File and Printer Sharing (Echo Request - ICMPv4-In)" new enable=yes >nul 2>&1
netsh advfirewall firewall set rule name="File and Printer Sharing (Echo Request - ICMPv6-In)" new enable=yes >nul 2>&1

if %errorLevel% equ 0 (
    echo [OK] Da kich hoat Firewall Rule cho ping thanh cong
) else (
    echo [WARNING] Co the da co loi khi thiet lap ICMP rules
)
echo.

REM 4. Create tvlm-custome-sc.bat file
echo [4/5] Dang tao file tvlm-custome-sc.bat...
(
echo @echo off
echo del %%temp%%\lstVol.txt
echo echo list volume^>^>%%temp%%\lstVol.txt
echo del %%temp%%\lstVoltv.txt
echo diskpart /s %%temp%%\lstVol.txt^>^>%%temp%%\lstVoltv.txt
echo del %%temp%%\lstVolExt.txt
echo For /f "tokens=2 delims= " %%%%A in ^('Type %%temp%%\lstVoltv.txt ^^| find /i "Boot"'^) do echo select volume %%%%A^>^>%%temp%%\lstVolExt.txt
echo echo extend^>^>%%temp%%\lstVolExt.txt
echo echo exit^>^>%%temp%%\lstVolExt.txt
echo diskpart /s %%temp%%\lstVolExt.txt
echo del %%temp%%\lstVolExt.txt
echo del %%temp%%\lstVol.txt
echo del %%temp%%\lstVoltv.txt
) > "%windir%\tvlm-custome-sc.bat"

if %errorLevel% equ 0 (
    echo [OK] Da tao file tvlm-custome-sc.bat thanh cong
) else (
    echo [ERROR] Khong the tao file tvlm-custome-sc.bat
)
echo.

REM 5. Add line to poweron-vm-default.bat if exists
echo [5/5] Dang cap nhat poweron-vm-default.bat...
if exist "C:\Program Files\VMware\VMware Tools\poweron-vm-default.bat" (
    echo %%windir%%\tvlm-custome-sc.bat >> "C:\Program Files\VMware\VMware Tools\poweron-vm-default.bat"
    echo [OK] Da cap nhat poweron-vm-default.bat thanh cong
) else (
    echo [WARNING] File poweron-vm-default.bat khong ton tai. Bo qua buoc nay.
)
echo.

REM Display system information
echo ===========================================================
echo                    THONG TIN HE THONG
echo ===========================================================
echo Timezone hien tai:
tzutil /g
echo.
echo Remote Desktop status:
reg query "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections | find "0x0" >nul
if %errorLevel% equ 0 (
    echo Remote Desktop: ENABLED
) else (
    echo Remote Desktop: DISABLED
)
echo.
echo Ngay gio hien tai: %date% %time%
echo.

echo ===========================================================
echo                 SETUP HOAN TAT THANH CONG!
echo ===========================================================
echo.
echo [QUAN TRONG] Vui long khoi dong lai may de cac thay doi co hieu luc.
echo.
echo Nhan phim bat ky de dong cua so...
pause >nul
