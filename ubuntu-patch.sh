#! /bin/bash

sudo sed -i \
  -e '/pam_pwquality.so/d' \
  -e '/pam_unix.so/i password\trequisite\t\t\tpam_pwquality.so retry=3 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 enforce_for_root' \
  /etc/pam.d/common-password