#!/usr/local/bin/bash

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin"

cd /root/manual-connections

PIA_TOKEN=$( cat /opt/piavpn-manual/token  )
rm /opt/piavpn-manual/token
OVPN_HOSTNAME=$( cat /opt/piavpn-manual/hostname )
ovpn_pid="/var/run/openvpn.pid"
PIA_PF="true"
sleep 5 # i don't want to actually test the connection. we'll just wait a bit instead.

##get the gateway ip by filtering ifconfig. i don't understand how it
##ended up in a file with pia scripts.
gateway_ip=$(ifconfig | sed -n 's/^.*-->[[:space:]]\([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\)[[:space:]]netmask.*/\1/p')

<< 'MULTILINE-COMMENT'
connection_wait_time=10
confirmation="Initialization Sequence Complete"
for (( timeout=0; timeout <=$connection_wait_time; timeout++ ))
do
  sleep 1
  if grep -q "$confirmation" /opt/piavpn-manual/debug_info; then
    connected=true
    break
  fi
done

ovpn_pid="$( cat /opt/piavpn-manual/pia_pid )"
echo "Reading gateway_ip from /opt/piavpn-manual/route_info"
gateway_ip="$( cat /opt/piavpn-manual/route_info )"

# Report and exit if connection was not initialized within 10 seconds.
if [ "$connected" != true ]; then
  echo "The VPN connection was not established within 10 seconds."
  kill $ovpn_pid
  echo \n"Openvpn debug info at /opt/piavpn-manual/debug_info:"
  cat  /opt/piavpn-manual/debug_info
  exit 1
fi

echo "Initialization Sequence Complete!

At this point, internet should work via VPN.
"
MULTILINE-COMMENT

echo "OpenVPN Process ID: $ovpn_pid
VPN route IP: $gateway_ip

To disconnect the VPN, run:

--> sudo kill $ovpn_pid <--
"

# This section will stop the script if PIA_PF is not set to "true".
if [ "$PIA_PF" != true ]; then
  echo
  echo If you want to also enable port forwarding, please start the script
  echo with the env var PIA_PF=true. Example:
  echo $ OVPN_SERVER_IP=\"$OVPN_SERVER_IP\" OVPN_HOSTNAME=\"$OVPN_HOSTNAME\" \
    PIA_TOKEN=\"$PIA_TOKEN\" CONNECTION_SETTINGS=\"$CONNECTION_SETTINGS\" \
    PIA_PF=true ./connect_to_openvpn_with_token.sh
  exit
fi

echo "
This script got started with PIA_PF=true.
Starting procedure to enable port forwarding by running the following command:
$ PIA_TOKEN=\"$PIA_TOKEN\" \\
  PF_GATEWAY=\"$gateway_ip\" \\
  PF_HOSTNAME=\"$OVPN_HOSTNAME\" \\
  ./port_forwarding.sh
"

PIA_TOKEN=$PIA_TOKEN \
  PF_GATEWAY="$gateway_ip" \
  PF_HOSTNAME="$OVPN_HOSTNAME" \
  ./port_forwarding.sh


