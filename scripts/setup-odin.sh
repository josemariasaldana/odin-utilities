#!/bin/bash

#################################################
# AP FRAN PC @ 172.16.250.175 / 192.168.250.201	#
#################################################

# The patched driver should be installed

# param 1: common tree local path
# e.g. /home/fran/bisdn
# e.g. /root/bisdn
LOCAL_PATH=$1
# param 2: wlanX
WLAN_IFACE=$2
# param 3: channel to set in click
NUM_CHANNEL=$3
# param 4: queue size to set in click
QUEUE_SIZE=$4
# param 5: IP address of the master
MASTER_IP=$5

mon_iface="mon0"

# Paths in local host
path_host_scripts="$LOCAL_PATH/spring-odin-patch/scripts"
path_host_click="$LOCAL_PATH/spring-click"
path_host_xdpd="$LOCAL_PATH/xdpd/build/src/xdpd"

# Paths inside the container
path_container_scripts="/root/spring/shared/scripts"
path_container_click="/root/spring/shared/click"
path_container_mask="/root/spring/shared/mask"

# For checking if network-manager is running
SERVICE='network-manager'
  
# xDPd wan interface
XDPD_WAN="eth1"

# xDPd DPID
DPID="0x001"

# This function is called when Ctrl-C is sent
function trap_ctrlc ()
{
   
    echo "*** CTRL-C pressed *** Cleaning up..."
    echo "Removing dockers..."
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    echo "Cleaning $mon_iface..." 
    iw dev $mon_iface del
    echo "Removing log files..."
    rm $path_host_scripts/odin.log
#    rm $path_host_scripts/hostapd.log
    rm $path_host_scripts/xdpd_output.log
    echo "Clean up completed"

    # exit shell script with error code 2
    # if omitted, shell script will continue execution
    exit 2
}

# Initialise trap to call trap_ctrlc function
# When signal 2 (SIGINT) is received
trap "trap_ctrlc" 2

if [ "$#" -ne 5 ]; then
    echo "Usage: setup-odin.sh [local_path] [wlanX] [click channel] [click queue] [master IP]"
    exit 1
fi  

clear all

echo ""
echo " ____ "
echo "/ ___| _ __  _ __(_)_ __   __ _" 
echo "\___ \| '_ \| '__| | '_ \ / _\` |"
echo " ___) | |_) | |  | | | | | (_| |"
echo "|____/| .__/|_|  |_|_| |_|\__, |"
echo "      |_|                 |___/ "
echo ""

# 
ifconfig mon0 mtu 2200

OPT_SHARED_SCRIPTS="$path_host_scripts/:$path_container_scripts/:rw"
OPT_SHARED_CLICK="$path_host_click/:$path_container_click/:rw"

# Find out mapping wlanX -> phyX
PHY=`cat /sys/class/net/$WLAN_IFACE/phy80211/name`

# Param for docker -v option
OPT_SHARED_MASK="/sys/kernel/debug/ieee80211/$PHY/ath9k_htc/:$path_container_mask/:rw"

if ps aux | grep -v grep | grep $SERVICE > /dev/null
then
    echo [+] Network manager is running
    echo [+] Turning nmcli wlan off --fix hostapd bug 1/2
    # Fix hostapd bug in Ubuntu 14.04
    nmcli nm wifi off
else
    echo [+] Network manager is stopped
fi

# Fix hostapd bug in Ubuntu 14.04
echo [+] Unblocking wlan --fix hostapd bug 2/2
rfkill unblock wlan
sleep 1

echo [+] Setting $WLAN_IFACE up
ifconfig $WLAN_IFACE up
sleep 1

echo [+] Setting $XDPD_WAN up
ifconfig $XDPD_WAN up
sleep 1

# Generate configuration for hostapd
echo "[+] Creating hostapd configuration file"
cd $path_host_scripts
python hostapd-cfg-generator.py "$WLAN_IFACE" "$NUM_CHANNEL" > hostapd_odin.cfg
sleep 1

# Start hostapd 
echo [+] Starting hostapd
`docker run -ti --net=host --privileged=true -v $OPT_SHARED_SCRIPTS fgg89/spring hostapd $path_container_scripts/hostapd_odin.cfg &`
sleep 1

# Check if $mon_iface exists, if not then create it
FOUND_MON0=`grep "$mon_iface" /proc/net/dev`
if  [ -n "$FOUND_MON0" ] ; then
	echo [+] $mon_iface had already been created...
else
	# Set mon0
	echo [+] Setting $WLAN_IFACE in monitor mode as: $mon_iface
	iw phy $PHY interface add $mon_iface type monitor
	echo [+] Setting $mon_iface in channel $NUM_CHANNEL
	iw dev $mon_iface set channel $NUM_CHANNEL
	echo [+] Setting $mon_iface up
	ifconfig $mon_iface up
	fi
sleep 1

# Create click conf file
echo "[+] Creating agent.click configuration file"
cd $path_host_scripts
python agent-generator.py "$NUM_CHANNEL" "$QUEUE_SIZE" "$MASTER_IP" "$path_container_mask/bssid_extra" > agent.click
sleep 1

# Create click start script
echo "[+] Creating click starting script"
cd $path_host_scripts
python click-starter-generator.py "$path_container_click" "$mon_iface" > start-click.sh
sleep 1


echo [+] Starting click
`docker run -ti --net=host --privileged=true -v $OPT_SHARED_MASK -v $OPT_SHARED_SCRIPTS -v $OPT_SHARED_CLICK fgg89/spring bash $path_container_scripts/start-click.sh &`
sleep 2

# Create xDPd conf file
echo "[+] Creating xDPd config file"
cd $path_host_scripts
python xdpd-conf-generator.py "$MASTER_IP" 6633 $XDPD_WAN $DPID > odin_conf.cfg
sleep 1

# Start the xDPd
echo [+] Starting xDPd
cd $path_host_xdpd
./xdpd -c $path_host_scripts/odin_conf.cfg -d 7 > $path_host_scripts/xdpd_output.log 2>&1 
