#!/bin/sh

CRYPT_USER="ed"
DEVICE="/dev/sda3"
MAPPER="/dev/mapper/home"

if [ "$PAM_USER" == "$CRYPT_USER" ] && [ ! -e $MAPPER ]
then
  tr '\0' '\n' | /usr/bin/cryptsetup open $DEVICE home
fi
