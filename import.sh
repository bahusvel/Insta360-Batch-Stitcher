#!/bin/bash

umount /mnt/insta360
mount -o ro /dev/insta360 /mnt/insta360

#if ! mountpoint /mnt/insta360; then
#	echo "Not Mounted"
#	exit 1
#fi

rsync -rvhP --update --size-only /mnt/insta360/DCIM/Camera*/ /hdd/media/Insta360/import/

umount /mnt/insta360
mail -s "Insta360 Import Complete" email@example.com <<< "You may now disconnect the camera."
