#!/bin/bash -e

USERNAME="doanac"
DRIVE="${DRIVE-/dev/sda}"
HOSTNAME="${HOSTNAME-asus}"
PACKAGES="alsa-utils aspell-en bash-completion cpupower mlocate net-tools openssh python sudo unzip wget zip dnsutils
   i3 terminator dmenu conky firefox thunderbird chromium
   lightdm lightdm-gtk-greeter xorg-server xf86-video-intel xf86-input-synaptics xorg-xrandr arandr xorg-xkill
   tex-gyre-fonts ttf-ubuntu-font-family ttf-dejavu ttf-liberation ttf-font-awesome
   acpi pulseaudio pavucontrol networkmanager network-manager-applet
   pass xdotool
   cmake gdb git tig tk gvim python-pip eslint tidy"

echo "=== Partitioning drive"
# 200 MB /boot partition, everything else under LVM
#parted -s $DRIVE \
#	mklabel msdos \
#	mkpart primary fat32 1 200M \
#	mkpart primary ext2 200M 100% \
#	set 1 boot on \
#	set 2 LVM on
#/dev/nvme0n1p1 = /boot/efi
#/dev/nvme0n1p2 = /boot
#/dev/nvme0n1p3 = crypt-luks


echo '=== Enter a passphrase to encrypt the disk:'
stty -echo
read passphrase
stty echo
#echo -en "$passphrase" | cryptsetup -c aes-xts-plain -y -s 512 luksFormat ${DRIVE}2
#echo -en "$passphrase" | cryptsetup luksOpen ${DRIVE}2 lvm
echo -en "$passphrase" | cryptsetup -c aes-xts-plain -y -s 512 luksFormat /dev/nvme0n1p3
echo -en "$passphrase" | cryptsetup luksOpen /dev/nvme0n1p3 lvm

echo "=== Partitioning the drive"
pvcreate /dev/mapper/lvm
vgcreate vg00 /dev/mapper/lvm
# Create a 1GB swap partition
lvcreate -C y -L1G vg00 -n swap
# Use the rest of the space for root
lvcreate -l '+100%FREE' vg00 -n root
# Enable the new volumes
vgchange -ay

#mkfs.fat -F32 ${DRIVE}1
mkfs.ext4 -L root /dev/vg00/root
mkswap /dev/vg00/swap

mount /dev/vg00/root /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot/efi
swapon /dev/vg00/swap

echo "=== Pacstrapping"
pacstrap /mnt base base-devel grub efibootmgr sudo nfs-utils dialog wpa_supplicant

echo "=== Configuring grub"
arch-chroot /mnt grub-install --efi-directory=/boot

echo "=== Fixing mkinitcpi.conf"
echo 'HOOKS=(base udev autodetect modconf block keymap keyboard encrypt lvm2 resume filesystems fsck)' >> /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -p linux

echo "=== Setting up fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Fixing grub"
sed -ie 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/nvme0n1p3:lvm"/' /mnt/etc/default/grub
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo "=== Creating a user: $USERNAME"
arch-chroot /mnt useradd -m -s /bin/bash -g users -G adm,systemd-journal,wheel,network $USERNAME
echo "setting password:"
arch-chroot /mnt passwd $USERNAME
echo "$USERNAME	ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/$USERNAME
echo "$USERNAME ALL=(ALL) NOPASSWD:/usr/sbin/pm-suspend" >> /mnt/etc/sudoers.d/$USERNAME
cat >>/mnt/etc/fstab <<EOF
# NFS mounts via systemd
192.168.0.120:/home  /storage	nfs	noauto,x-systemd.automount 0 0
192.168.0.133:/data/code  /code	nfs	noauto,x-systemd.automount 0 0
EOF
mkdir /mnt/code
mkdir /mnt/storage
arch-chroot /mnt chown $USERNAME /code
arch-chroot /mnt chown $USERNAME /storage

echo "=== Configuring system"
echo $HOSTNAME > /mnt/etc/hostname
rm -rf /mnt/etc/localtime
ln -sT "/usr/share/zoneinfo/America/Chicago" /mnt/etc/localtime

echo 'LANG="en_US.UTF-8"' >> /mnt/etc/locale.conf
echo 'LC_COLLATE="C"' >> /mnt/etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

cat >/mnt/etc/hosts <<EOF
127.0.0.1	localhost
127.0.1.1	$HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

arch-chroot /mnt pacman -S intel-ucode $PACKAGES
echo 'microcode' > /mnt/etc/modules-load.d/intel-ucode.conf

cat >>/mnt/etc/pacman.conf <<EOF
# ANDY for yaourt
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch
EOF
arch-chroot /mnt pacman -Sy yaourt

echo "Run this script after first boot: /home/$USERNAME/firstboot.sh"
cat >/mnt/home/$USERNAME/firstboot.sh <<EOF
#!/bin/sh -ex
systemctl mask tmp.mount
timedatectl set-ntp true
systemctl enable cpupower.service
systemctl enable lightdm.service

yaourt -S google-cloud-sdk
gcloud components install kubectl

echo "# From andy's arch-install.sh script" > /etc/profile.d/gcloud
echo "PATH=$PATH:/opt/google-cloud-sdk/bin" >> /etc/profile.d/gcloud
EOF
chmod +x /mnt/home/$USERNAME/firstboot.sh

