set -e

echo "[1] Auto update packages..."
apt update -y && apt upgrade -y

echo "[2] Set timezone Asia/Ho_Chi_Minh..."
timedatectl set-timezone Asia/Ho_Chi_Minh

echo "[3] Install additional package"
apt install open-vm-tools cloud-guest-utils

echo "[4] Install strong password policy..."
apt install -y libpam-pwquality

# Xóa mọi dòng pam_pwquality.so hiện có
sed -i '/pam_pwquality.so/d' /etc/pam.d/common-password

# Thêm lại cấu hình mạnh
echo "password requisite pam_pwquality.so retry=3 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 enforce_for_root" >> /etc/pam.d/common-password

echo "[5] Enable SSH for root..."
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh

echo "[6] Resize sda3 to full capacity..."
pvresize /dev/sda3 || true
growpart /dev/sda 3 || true
lvextend -l +100%FREE /dev/debian-vg/root || true
resize2fs /dev/debian-vg/root || true

echo "[7] Create rc.local for first boot..."
cat << 'EOF' > /etc/rc.local
#!/bin/bash
/home/arp.sh
exit 0
EOF
chmod 755 /etc/rc.local

echo "[8] Create arp.sh (auto resize partition on first boot)..."
cat << 'EOF' > /home/arp.sh
#!/bin/bash
echo "1" >/sys/class/block/sda/device/rescan
growpart /dev/sda 3
pvresize /dev/sda3
lvextend -l +100%FREE /dev/debian-vg/root
resize2fs /dev/debian-vg/root
NETWORK_CONFIG="/etc/network/interfaces"
TIMEOUT=30
for i in $(seq 1 $TIMEOUT); do
	if [ -f "$NETWORK_CONFIG" ]; then
		echo "Network configuration file found, restarting networking.service"
		# Restart networking service
		systemctl restart networking.service
		break
	fi
	echo "Waiting for $NETWORK_CONFIG ($i/$TIMEOUT)..."
	sleep 1
done
rm -f /etc/rc.local
rm -f /home/arp.sh
history -c
EOF
chmod 755 /home/arp.sh

echo "[9] Setup network..."
rm /etc/network/interfaces
# SERVICE_FILE="/lib/systemd/system/networking.service"
# sed -i '/^After=/ s/$/ vmtoolsd.service open-vm-tools.service/' "$SERVICE_FILE"

rm -f /var/lib/systemd/lease/*

echo "[10] Clear machine ID..."
truncate -s0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "[11] Clear logs..."
echo > /var/log/wtmp
rm -f ~/.bash_history
journalctl --rotate
journalctl --vacuum-time=1s
history -c

echo "[12] Done. Self-destructing..."
shred -u "$0"
