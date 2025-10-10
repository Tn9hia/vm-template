# VM Windows Setup Script
# Chạy với quyền Administrator
# Tải file bằng lệnh sau: irm <link> | iex

Write-Host "=== VM Windows Setup Script ===" -ForegroundColor Green
Write-Host "Đang thiết lập VM Windows..." -ForegroundColor Yellow

# 1. Chỉnh Date & Time về GMT +7 (SE Asia Standard Time)
Write-Host "`n1. Đang thiết lập timezone GMT+7..." -ForegroundColor Cyan
try {
    Set-TimeZone -Id "SE Asia Standard Time" -Verbose
    Write-Host "✓ Đã thiết lập timezone thành công" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi khi thiết lập timezone: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Enable Remote Desktop
Write-Host "`n2. Đang kích hoạt Remote Desktop..." -ForegroundColor Cyan
try {
    # Enable Remote Desktop
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    
    # Enable Remote Desktop through Windows Firewall
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    # Optional: Allow connections from computers running any version of Remote Desktop (less secure)
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -value 1
    
    Write-Host "✓ Đã kích hoạt Remote Desktop thành công" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi khi kích hoạt Remote Desktop: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Enable Firewall Rule để ping (ICMP)
Write-Host "`n3. Đang kích hoạt Firewall Rule cho ping..." -ForegroundColor Cyan
try {
    # Enable ICMP Echo Request (ping) - IPv4
    New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow -ErrorAction SilentlyContinue
    
    # Enable ICMP Echo Request (ping) - IPv6
    New-NetFirewallRule -DisplayName "Allow ICMPv6-In" -Direction Inbound -Protocol ICMPv6 -IcmpType 128 -Action Allow -ErrorAction SilentlyContinue
    
    # Hoặc enable rule có sẵn nếu tồn tại
    Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue
    Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)" -ErrorAction SilentlyContinue
    
    Write-Host "✓ Đã kích hoạt Firewall Rule cho ping thành công" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi khi kích hoạt Firewall Rule: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Tạo file tvlm-custome-sc.bat trong C:\Windows
Write-Host "`n4. Đang tạo file tvlm-custome-sc.bat..." -ForegroundColor Cyan
$batchContent = @'
@echo off
del %temp%\lstVol.txt
echo list volume>>%temp%\lstVol.txt
del %temp%\lstVoltv.txt
diskpart /s %temp%\lstVol.txt>>%temp%\lstVoltv.txt
del %temp%\lstVolExt.txt
For /f "tokens=2 delims= " %%A in ('Type %temp%\lstVoltv.txt ^| find /i "Boot"') do echo select volume %%A>>%temp%\lstVolExt.txt
echo extend>>%temp%\lstVolExt.txt
echo exit>>%temp%\lstVolExt.txt
diskpart /s %temp%\lstVolExt.txt
del %temp%\lstVolExt.txt
del %temp%\lstVol.txt
del %temp%\lstVoltv.txt
'@

try {
    $batchContent | Out-File -FilePath "C:\Windows\tvlm-custome-sc.bat" -Encoding ASCII -Force
    Write-Host "✓ Đã tạo file tvlm-custome-sc.bat thành công" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi khi tạo file tvlm-custome-sc.bat: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Thêm dòng vào poweron-vm-default.bat (nếu file tồn tại)
Write-Host "`n5. Đang cập nhật poweron-vm-default.bat..." -ForegroundColor Cyan
$vmwareToolsPath = "C:\Program Files\VMware\VMware Tools\poweron-vm-default.bat"
if (Test-Path $vmwareToolsPath) {
    try {
        $newLine = "%windir%\tvlm-custome-sc.bat"
        Add-Content -Path $vmwareToolsPath -Value $newLine -Encoding ASCII
        Write-Host "✓ Đã cập nhật poweron-vm-default.bat thành công" -ForegroundColor Green
    } catch {
        Write-Host "✗ Lỗi khi cập nhật poweron-vm-default.bat: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "! File poweron-vm-default.bat không tồn tại. Bỏ qua bước này." -ForegroundColor Yellow
}

Write-Host "`n=== Setup hoàn tất ===" -ForegroundColor Green
Write-Host "Vui lòng khởi động lại máy để các thay đổi có hiệu lực." -ForegroundColor Yellow

# Hiển thị thông tin hệ thống
Write-Host "`n=== Thông tin hệ thống ===" -ForegroundColor Cyan
Write-Host "Timezone hiện tại: $((Get-TimeZone).DisplayName)"
Write-Host "Remote Desktop: $((Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections -eq 0)"
Write-Host "Ngày giờ hiện tại: $(Get-Date)"
