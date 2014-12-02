
odinagent::OdinAgent(10-0b-a9-f1-e0-60, RT rates, CHANNEL 4, DEFAULT_GW 10.0.0.1, DEBUGFS /root/spring/shared/mask/bssid_extra)
TimedSource(2, "ping
")->  odinsocket::Socket(UDP, 172.16.250.170, 2819, CLIENT true)



odinagent[3] -> odinsocket

rates :: AvailableRates(DEFAULT 24 36 48 108);

control :: ControlSocket("TCP", 6777);
chatter :: ChatterSocket("TCP", 6778);

// ----------------Packets going down
// 12 = offset, 0806 = arp, 20 = offset, 0001 = type request, output 1, rest to output 2
// The arp responder configuration here doesnt matter, odinagent.cc sets it according to clients
FromHost(ap, HEADROOM 50)
  -> fhcl :: Classifier(12/0806 20/0001, -)
  -> fh_arpr :: ARPResponder(172.17.250.170 98:d6:f7:67:6b:ee) // Resolve STA's ARP
  -> ARPPrint("Resolving client's ARP by myself")
  -> ToHost(ap)



q :: Queue(200)
  -> SetTXRate (108)
  -> RadiotapEncap()
  -> to_dev :: ToDevice (mon0);

// Anything from host that isn't an ARP request
fhcl[1]
  -> [1]odinagent



// Not looking for an STA's ARP? Then let it pass.
fh_arpr[1]
  -> [1]odinagent

odinagent[2]
  -> q

// ----------------Packets going down


// ----------------Packets coming up
from_dev :: FromDevice(mon0, HEADROOM 50)
  -> RadiotapDecap()
  -> ExtraDecap()
  -> phyerr_filter :: FilterPhyErr()
  -> tx_filter :: FilterTX()
  -> dupe :: WifiDupeFilter()
  -> [0]odinagent

odinagent[0]
  -> q

// Data frames
// The arp responder configuration here doesnt matter, odinagent.cc sets it according to clients
odinagent[1]
  -> decap :: WifiDecap()
  -> RXStats
  -> arp_c :: Classifier(12/0806 20/0001, -)
  -> arp_resp::ARPResponder (172.16.250.170 00-1B-B3-67-6B-EE) // ARP fast path for STA
  -> [1]odinagent


// ARP Fast path fail. Re-write MAC address
// to reflect datapath or learning switch will drop it
arp_resp[1]
  -> ToHost(ap)



// Non ARP packets. Re-write MAC address to
// reflect datapath or learning switch will drop it
arp_c[1]
  -> ToHost(ap)

