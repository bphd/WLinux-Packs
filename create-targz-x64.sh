#!/bin/bash

# install script dependencies
sudo apt update
sudo apt -y install curl gnupg cdebootstrap

# create our environment
set -e
BUILDIR=$(pwd)
TMPDIR=$(mktemp -d)
ARCH="amd64"
DIST="testing"
cd $TMPDIR

# bootstrap image
sudo cdebootstrap -a $ARCH --include=sudo,locales,git,ssh,apt-transport-https,wget,ca-certificates,man,less,curl $DIST $DIST http://deb.debian.org/debian

# clean apt cache
sudo chroot $DIST apt-get clean

# configure bash
sudo chroot $DIST /bin/bash -c "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen"
sudo chroot $DIST /bin/bash -c "update-locale LANGUAGE=en_US.UTF-8 LC_ALL=C"

# download and copy latest wslu repo key
curl https://repo.whitewaterfoundry.com/public.key | gpg --dearmor > $BUILDIR/wlinux.gpg
sudo cp $BUILDIR/wlinux.gpg $TMPDIR/$DIST/etc/apt/trusted.gpg.d/wlinux.gpg
rm $BUILDIR/wlinux.gpg
sudo chroot $DIST chmod 644 /etc/apt/trusted.gpg.d/wlinux.gpg
sudo chroot $DIST apt update
sudo chroot $DIST apt -y install wlinux-wslu wlinux-setup wlinux-security

# the sudoers lecture is one of the first things users see when they run /etc/setup, it is a bit jarring, and a bit out of place on WSL, so let's make it a bit more friendly
sudo chroot $DIST /bin/bash -c "echo 'Defaults lecture_file = /etc/sudoers.lecture' >> /etc/sudoers"
sudo chroot $DIST /bin/bash -c "echo 'Enter your UNIX password below. This is not your Windows password.' >> /etc/sudoers.lecture"

# remove unnecessary apt packages
sudo chroot $DIST apt remove systemd dmidecode -y --allow-remove-essential

# clean up orphaned apt dependencies
sudo chroot $DIST apt-get autoremove -y

# create tar
cd $DIST
sudo tar --ignore-failed-read -czvf $TMPDIR/install.tar.gz *

# move into place in build folder
cd $TMPDIR
cp install.tar.gz $BUILDIR/x64/
cd $BUILDIR