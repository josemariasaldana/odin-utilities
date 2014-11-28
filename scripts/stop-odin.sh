docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
iw dev mon0 del
rm ~/bisdn/docker_shared/odin.log
rm ~/bisdn/docker_shared/hostapd.log
rm ~/bisdn/docker_shared/xdpd_output.log

