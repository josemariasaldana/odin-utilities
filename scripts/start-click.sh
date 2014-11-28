
#!/bin/bash

cd /root/spring/shared/click
./tools/click-align/click-align agent.click | ./userlevel/click &> odin.log
sleep 3
ifconfig ap up
ifconfig mon0 mtu 2200

