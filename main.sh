#!/bin/bash

# Sources:
# iPhone USB Thetering to RPi: https://gist.github.com/antronic/157e047cdefa98b3150195c2eacb56b8
#    Installs things necessary for the iPhone to be able to tether via USB
# Raspberry PI Portable Hotspot: https://peppe8o.com/raspberry-pi-portable-hotspot-with-android-usb-tethering/
#    Shares USB internet to WiFi on a Raspberry Pi Zero. Will use as a reference.
# Bridging internet to Ethernet from WiFi - Raspberry Pi: https://www.elementzonline.com/blog/sharing-or-bridging-internet-to-ethernet-from-wifi-raspberry-pI


# 0. Define the name of the source interface. All interfaces can be listed using ifconfig -s
# wifi tends to be wlan0, ethernet tends to be eth0. iPhone in my case is enp1s0u1
SOURCE_INTERFACE=enp1s0u1

# 1. Install iphone things (taken from https://gist.github.com/antronic/157e047cdefa98b3150195c2eacb56b8)
sudo apt install -y usbmuxd ipheth-utils libimobiledevice-utils

# 2. Install DNS server
sudo apt install -y dnsmasq

# 3. Enable fix IP address on the Ethernet port
sudo cp dhcpcd.conf /etc/dhcpcd.conf
sudo service dhcpcd restart

# 4. Configure DHCP and DNS
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup-`date '+%Y-%m-%d_%H:%M:%S'`
sudo cp dnsmasq.conf /etc/dnsmasq.conf
sudo cp ethernet.conf /etc/dnsmasq.d/ethernet.conf

# 5. Enable IP forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# 6. IP tables
sudo iptables -t nat -A POSTROUTING -o $SOURCE_INTERFACE -j MASQUERADE  
sudo iptables -A FORWARD -i $SOURCE_INTERFACE -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
sudo iptables -A FORWARD -i eth0 -o $SOURCE_INTERFACE -j ACCEPT

# 7. Write script to enable IP tables on startup
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo sed -i 's/exit 0//g' /etc/rc.local
sudo echo "iptables-restore < /etc/iptables.ipv4.nat" /etc/rc.local
sudo echo "exit 0" >> /etc/rc.local

# 8. Start
sudo service dnsmasq start