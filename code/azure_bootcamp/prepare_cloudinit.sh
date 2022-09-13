#!/bin/sh
#
# prepare_cloudinit.sh
#
# usage:
#   sh prepare_cloudinit.sh message

# --- check args ---
if [ $# -ne 1 ]; then
  echo "ERROR: Please specify Message (1 arg)." 1>&2
  exit 1
fi
MESSAGE=$1

# -- copy template-file to work-file --
cp cloud-init-template.txt cloud-init-work.txt

# -- replace message variable --
sed -i.bak "s/HELLOMESSAGE/$MESSAGE/" cloud-init-work.txt
