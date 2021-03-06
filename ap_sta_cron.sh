#!/bin/bash
# The script configures simultaneous AP and Managed Mode Wifi on Raspberry Pi
# Distribution Raspbian Buster
# works on:
#           -Raspberry Pi Zero W
#           -Raspberry Pi 3 B+
#           -Raspberry Pi 3 A+
# Licence: GPLv3
# Author: Mickael Lehoux <mickael.lehoux@gmail.com>
# Special thanks to: https://github.com/lukicdarkoo/rpi-wifi

# set -exv

DEFAULT='\033[0;39m'
WHITE='\033[0;02m'
RASPBERRY='\033[0;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'

_logger() {
    echo -e "${GREEN}"
    echo "${1}"
    echo -e "${DEFAULT}"
}

if [ $(id -u) != 0 ]; then
    echo -e "${RED}"
    echo "You need to be root to run this script"
    echo "Please run 'sudo bash $0'"
    echo -e "${DEFAULT}"
    exit 1
fi

check_crontab_initialized=$(crontab -l | grep -cF "# comment for crontab init")
if test 1 != $check_crontab_initialized; then
    # Check if crontab exist for "sudo user"
    _logger "init crontab first time by adding comment"
    crontab -l >cron_jobs
    echo -e "# comment for crontab init\n" >>cron_jobs
    crontab cron_jobs
    rm cron_jobs
else
    _logger "Crontab already initialized"
fi

# Create hostapd ap0 monitor
_logger "Create hostapd ap0 monitor cronjob"
# do not create the same cronjob if exist
cron_jobs=/tmp/tmp.cron
cronjob_1=$(crontab -l | grep -cF "* * * * * /bin/bash /bin/manage-ap0-iface.sh >> /var/log/ap_sta_wifi/ap0_mgnt.log 2>&1")
if test 1 != $cronjob_1; then
    # crontab -l | { cat; echo -e "# Start hostapd when ap0 already exists\n* * * * * /bin/manage-ap0-iface.sh >> /var/log/ap_sta_wifi/ap0_mgnt.log 2>&1\n"; } | crontab -
    crontab -l >$cron_jobs
    echo -e "# Start hostapd when ap0 already exists\n* * * * * /bin/bash /bin/manage-ap0-iface.sh >> /var/log/ap_sta_wifi/ap0_mgnt.log 2>&1\n" >>$cron_jobs
    crontab <$cron_jobs
    rm $cron_jobs
    _logger "Cronjob created"
else
    _logger "Crontjob exist"
fi
# Create AP + STA cronjob boot on start
_logger "Create AP and STA Client cronjob"
# do not create the same cronjob if exist
cronjob_2=$(crontab -l | grep -cF "@reboot sleep 20 && /bin/bash /bin/rpi-wifi.sh >> /var/log/ap_sta_wifi/on_boot.log 2>&1")
if test 1 != $cronjob_2; then
    # crontab -l | { cat; echo -e "# On boot start AP + STA config\n@reboot sleep 20 && /bin/bash /bin/rpi-wifi.sh >> /var/log/ap_sta_wifi/on_boot.log 2>&1\n"; } | crontab -
    crontab -l >cron_jobs
    echo -e "# On boot start AP + STA config\n@reboot sleep 20 && /bin/bash /bin/rpi-wifi.sh >> /var/log/ap_sta_wifi/on_boot.log 2>&1\n" >>cron_jobs
    crontab <cron_jobs
    rm cron_jobs
    _logger "Cronjob created"
else
    _logger "Cronjob exist"
fi

