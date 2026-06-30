# VM Template Scripts

Tập hợp các script shell để chuẩn hóa VM trên VMware trước khi chuyển đổi thành template. Hỗ trợ Ubuntu, Debian và AlmaLinux.

## Các script

| Script | Distro | Phiên bản hỗ trợ |
|---|---|---|
| `ubuntu.sh` | Ubuntu | 22.04, 24.04 |
| `debian.sh` | Debian | 11, 12 |
| `almalinux.sh` | AlmaLinux | 8, 9, 10 |
| `ubuntu-patch.sh` | Ubuntu | Patch riêng cho password policy |

## Những gì script thực hiện

Mỗi script sẽ thực hiện các bước sau theo thứ tự:

1. **Cập nhật hệ thống** — `apt upgrade` / `dnf upgrade`
2. **Đặt timezone** — `Asia/Ho_Chi_Minh`
3. **Cài open-vm-tools** — enable và start service
4. **Cấu hình password policy mạnh** — `pam_pwquality` với yêu cầu tối thiểu 8 ký tự, có chữ hoa, chữ thường, số, ký tự đặc biệt
5. **Bật SSH root login** — cài openssh-server, sửa `sshd_config`
6. **Resize disk** — mở rộng partition và logical volume về tối đa
7. **Tạo `arp.sh`** — script tự động resize disk khi boot lần đầu sau khi clone
8. **Dọn network config** — xóa netplan/interfaces cũ để tránh xung đột IP sau khi clone
9. **Xóa machine-id** — `truncate /etc/machine-id` để VM clone nhận ID mới
10. **Xóa logs và history** — `journalctl`, `wtmp`, `bash_history`
11. **Tự hủy** — `shred -u "$0"` (script tự xóa sau khi chạy xong)

## Hướng dẫn sử dụng

### Yêu cầu
- VM đang chạy trên VMware (vSphere / Workstation / Fusion)
- Đăng nhập với quyền `root`
- Disk layout mặc định: `sda` với LVM trên partition 3

### Các bước thực hiện

**Bước 1:** Tải script vào VM

```bash
# Cách 1: dùng curl
curl -O https://raw.githubusercontent.com/Tn9hia/vm-template/main/ubuntu.sh

# Cách 2: copy trực tiếp qua SSH/SCP
scp ubuntu.sh root@<VM_IP>:/root/
```

**Bước 2:** Cấp quyền thực thi và chạy script tương ứng với distro

```bash
# Ubuntu
chmod +x ubuntu.sh && ./ubuntu.sh

# Debian
chmod +x debian.sh && ./debian.sh

# AlmaLinux
chmod +x almalinux.sh && ./almalinux.sh
```

**Bước 3:** Sau khi script hoàn tất, xóa user mặc định (nếu có) rồi shutdown

```bash
# Xóa user cài sẵn (ví dụ Ubuntu tạo user trong quá trình cài)
userdel -r ubuntu   # hoặc tên user khác

# Xóa history lần cuối
history -c && history -w

# Shutdown VM
shutdown -h now
```

**Bước 4:** Trên vSphere/vCenter, chuyển VM thành template:
`Right-click VM → Convert to Template`

### Patch Ubuntu (password policy)

Nếu cần áp lại cấu hình password policy riêng trên Ubuntu mà không chạy toàn bộ script:

```bash
chmod +x ubuntu-patch.sh && ./ubuntu-patch.sh
```

## Cơ chế auto-resize khi clone

Khi clone VM từ template, disk mới có thể có kích thước lớn hơn. Script `arp.sh` được nhúng vào VM và sẽ tự động chạy một lần lúc boot để:

1. Rescan thiết bị block (`sda`)
2. Mở rộng partition 3 (`growpart`)
3. Resize PV và LV (`pvresize`, `lvextend`)
4. Mở rộng filesystem (`resize2fs` / `xfs_growfs`)
5. Tự xóa bản thân và service sau khi hoàn tất

**Ubuntu/Debian:** `arp.sh` chạy qua `/etc/rc.local`  
**AlmaLinux:** `arp.sh` chạy qua systemd service `arp-resize.service`

## Lưu ý

- Script dùng `set -e` — nếu một bước thất bại, toàn bộ quá trình dừng lại.
- Disk layout giả định là `sda` + LVM. Nếu dùng disk khác (`sdb`, `nvme0n1`...) cần chỉnh tay trước khi chạy.
- Tên LVM volume group mặc định theo từng distro:
  - Ubuntu: `ubuntu-vg/ubuntu-lv`
  - Debian: `debian-vg/root`
  - AlmaLinux: `almalinux/root` (mapper)
- Sau khi script chạy xong, **không restart VM** trước khi convert — machine-id đã bị xóa và sẽ được tạo lại khi boot lần đầu từ clone.
