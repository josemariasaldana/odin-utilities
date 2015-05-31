PATH_LOGS="/home/fran/bisdn/fran-github/odin/odin-utilities/scripts"

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
iw dev mon0 del
#rm $PATH_LOGS/odin.log
#rm $PATH_LOGS/hostapd.log
rm $PATH_LOGS/xdpd_output.log
killall click
ovs-vsctl del-port br0 eth0
ovs-vsctl del-br br0
service openvswitch-switch stop
