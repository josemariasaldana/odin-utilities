
#!/bin/bash

cd /root/spring/shared/click
./tools/click-align/click-align ../scripts/agent.click | ./userlevel/click &> ../scripts/odin.log
sleep 3
ifconfig ap up
#ifconfig mon0 mtu 2200

