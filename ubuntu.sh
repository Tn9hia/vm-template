#!/bin/bash
# Script chuẩn hóa VM Ubuntu 20.04, 22.04, 24.04 cho template
# WARNING: Script này sẽ thay đổi nhiều cấu hình hệ thống

set -e

echo "[1] Auto update packages..."
apt update -y && apt upgrade -y

echo "[2] Set timezone Asia/Ho_Chi_Minh..."
timedatectl set-timezone Asia/Ho_Chi_Minh

echo "[3] Install VMware Tools..."
apt install -y open-vm-tools

echo "[4] Remove cloud-init network cfg..."
rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg

echo "[5] Install strong password policy..."
apt install -y libpam-pwquality

# Xóa mọi dòng pam_pwquality.so hiện có
sed -i '/pam_pwquality.so/d' /etc/pam.d/common-password

# Thêm lại cấu hình mạnh
echo "password requisite pam_pwquality.so retry=3 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 enforce_for_root" >> /etc/pam.d/common-password


echo "[6] Enable SSH for root..."
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh

echo "[7] Resize sda3 to full capacity..."
pvresize /dev/sda3 || true
growpart /dev/sda 3 || true
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv || true
resize2fs /dev/ubuntu-vg/ubuntu-lv || true

echo "[8] Create rc.local for first boot..."
cat << 'EOF' > /etc/rc.local
#!/bin/bash
/home/arp.sh
exit 0
EOF
chmod 755 /etc/rc.local

echo "[9] Create arp.sh (auto resize partition on first boot)..."
cat << 'EOF' > /home/arp.sh
#!/bin/bash
echo "1" >/sys/class/block/sda/device/rescan
growpart /dev/sda 3
pvresize /dev/sda3
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv
rm -f /etc/rc.local
rm -f /home/arp.sh
history -c
EOF
chmod 755 /home/arp.sh

echo "[10] Remove netplan config..."
rm -f /etc/netplan/*.yaml

echo "[11] Clear machine ID..."
truncate -s0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "[12] Disable cloud-init..."
cloud-init clean
touch /etc/cloud/cloud-init.disabled

echo "[13] Clear logs..."
echo > /var/log/wtmp
rm -f ~/.bash_history
history -c

echo "[14] Done. Self-destructing..."
shred -u "$0"
