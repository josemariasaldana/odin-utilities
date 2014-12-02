
import sys
if (len(sys.argv) != 3):
    print 'Usage:'
    print 'click-starter-generator.py <CLICK_PATH> <MON_IFACE> '
    sys.exit(0)

CLICK_PATH = sys.argv[1]
MON_IFACE = sys.argv[2]
AP_IFACE = "ap"

print '''
#!/bin/bash

cd %s
./tools/click-align/click-align ../scripts/agent.click | ./userlevel/click &> ../scripts/odin.log
sleep 3
ifconfig %s up
#ifconfig %s mtu 2200
''' % (CLICK_PATH, AP_IFACE, MON_IFACE)

