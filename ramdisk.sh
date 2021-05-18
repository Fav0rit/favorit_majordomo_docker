#!/bin/sh

path_mysql_tmp="/opt/favorit_majordomo_docker/app/data/mysql"

docker-compose down

sudo mv ./app/data/mysql ./app/data/mysql_real
sudo cp ./config/ramdisk /etc/init.d/ramdisk
sudo update-rc.d ramdisk defaults

echo "tmpfs $path_mysql_tmp tmpfs size=350m 0 0" >> /etc/fstab
echo "*/10 * * * * root /etc/init.d/ramdisk sync >> /dev/null 2>&1" >> /etc/crontab

#sudo reboot