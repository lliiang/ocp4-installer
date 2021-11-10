#!/bin/sh

OCP_VERSION=4.8.14
YUM_HOST=172.31.60.10:8081
NIC_NAME=ens192
GATEWAY=172.31.60.254
NETMASK=255.255.255.0
DNS_IP=172.31.60.10
OCP_ID=ocp-dev
BOOT_DISK=sda
DOMAIN=example.internal
NODE_NAME="$(hostname).${OCP_ID}.${DOMAIN}"
IP=$(ip a|grep $NIC_NAME|grep -v mtu|awk '{print $2}'|awk -F/ '{print $1}')

yum install wget -y

cd /boot
wget http://${YUM_HOST}/coreos/${OCP_VERSION}/rhcos-${OCP_VERSION}-x86_64-live-initramfs.x86_64.img
wget http://${YUM_HOST}/coreos/${OCP_VERSION}/rhcos-${OCP_VERSION}-x86_64-live-kernel-x86_64


RHCOS_METAL_URL=http://${YUM_HOST}/coreos/${OCP_VERSION}/rhcos-${OCP_VERSION}-x86_64-metal.x86_64.raw.gz
ROOTFS_IMG=http://${YUM_HOST}/coreos/${OCP_VERSION}/rhcos-${OCP_VERSION}-x86_64-live-rootfs.x86_64.img
INITRAMFS_IMG=http://${YUM_HOST}/coreos/${OCP_VERSION}/rhcos-${OCP_VERSION}-x86_64-live-initramfs.x86_64.img
IGN_URL=http://${YUM_HOST}/ignition/${OCP_ID}/$1.ign

cat >>/etc/grub.d/40_custom <<EOF
menuentry 'RHEL CoreOS (Live)' --class fedora --class gnu-linux --class gnu --class os {
        linux /rhcos-${OCP_VERSION}-x86_64-live-kernel-x86_64  random.trust_cpu=on rd.luks.options=discard  ignition.firstboot ignition.platform.id=metal coreos.live.rootfs_url=${ROOTFS_IMG} coreos.inst=yes rd.neednet=1 coreos.inst.insecure coreos.inst.install_dev=${BOOT_DISK} coreos.inst.image_url=${RHCOS_METAL_URL} coreos.inst.ignition_url=${IGN_URL} ip=${IP}::${GATEWAY}:${NETMASK}:${NODE_NAME}:${NIC_NAME}:none nameserver=${DNS_IP}
        initrd /rhcos-${OCP_VERSION}-x86_64-live-initramfs.x86_64.img
}
EOF

grub2-set-default 'RHEL CoreOS (Live)'

# bios
grub2-mkconfig -o /boot/grub2/grub.cfg

#uefi
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg