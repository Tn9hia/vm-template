# update system
dnf update -y && dnf upgrade -y

# set timezone
timedatectl set-timezone Asia/Ho_Chi_Minh

# install necessary package
dnf install -y perl open-vm-tools cloud-utils-growpart

# set password policy
sed -i 's|^password\s\+requisite\s\+pam_pwquality.so.*|password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 enforce_for_root|' /etc/pam.d/system-auth

# setup network
INTERFACE="ens192"
CONNECTION_NAME="ens192"

echo "Deleting old connection..."
nmcli connection delete "$CONNECTION_NAME" 2>/dev/null || true

echo "Creating new connection with new UUID..."
nmcli connection add type ethernet con-name "$CONNECTION_NAME" ifname "$INTERFACE"

echo "Configuring network settings..."
nmcli connection modify "$CONNECTION_NAME" ipv4.method auto
nmcli connection modify "$CONNECTION_NAME" ipv6.method ignore  
nmcli connection modify "$CONNECTION_NAME" connection.autoconnect yes

# Xóa cloned MAC address (nếu có)
nmcli connection modify "$CONNECTION_NAME" 802-3-ethernet.cloned-mac-address ""

echo "Cleaning up lease files and udev rules..."
rm -f /var/lib/NetworkManager/*.lease
rm -f /etc/udev/rules.d/70-persistent-net.rules

echo "Restarting NetworkManager..."
systemctl enable NetworkManager
systemctl restart NetworkManager

# script resize
cat <<'EOF' > /usr/local/bin/arp.sh
#!/bin/bash
echo "1" >/sys/class/block/sda/device/rescan
growpart /dev/sda 3
pvresize /dev/sda3
lvextend -l +100%FREE /dev/mapper/almalinux-root
xfs_growfs /dev/mapper/almalinux-root
systemctl disable arp-resize.service
rm -f /etc/systemd/system/arp-resize.service
systemctl daemon-reload
rm -f /usr/local/bin/arp.sh
EOF

chmod +x /usr/local/bin/arp.sh

# create systemd unit file
cat <<'EOF' > /etc/systemd/system/arp-resize.service
[Unit]
Description=Auto resize partition on boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/arp.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

systemctl enable arp-resize.service

# clear machine_id
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
