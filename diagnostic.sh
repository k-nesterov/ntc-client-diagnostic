#!/bin/bash

## passing parameters to a Bash function ##
F_PING_HOST(){
	PING_RESULT=""
	SRC_INT=$1
	DST_IP=$2
	PING_RESULT=$(ping -I $SRC_INT -c 5 -q $DST_IP | grep -E 'transmitted|mdev')
}

if [[ $# -lt 2 ]] ; then
    echo 'no arguments'
    exit 1
fi

RESULT_FILE=$1
OPENVPN_INT=$2
#RESULT_FILE="/tmp/RESULT_FILE.txt"
#OPENVPN_INT="tun0"

# collect os info
MEMORY="MEMORY: $(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2}')"
CPU="CPU: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' | sed 's/\([0-9]\{1,2\}\.\)\([0-9]\{1,2\}\).*/\1\2/g')%"
UPTIME="UPTIME: $(uptime | awk '{print $1,$2,$3,$4,$5}' | sed 's/,//g')"


# get comma-separated interfaces list with its ip addresses and mask:
# eth0=192.168.1.0/24, eth1=172.16.100.194/25
IPLIST="IP LIST: $(ip -4 -o addr | awk '{print $2"="$4}' | grep -v '^lo' | tr '\n' ',' | sed 's/,$//g;s/,/, /g')"

ROUTING_TABLE=$(ip -4 route show)


# get default gateway interface name and ip address
DEFAULT_GATEWAY_IP=$(echo $ROUTING_TABLE | grep 'default' | awk '{print $3}')
DEFAULT_GATEWAY_INT=$(echo $ROUTING_TABLE | grep 'default' | awk '{print $5}')
OPENVPN_GATEWAY=$(echo $ROUTING_TABLE | grep $OPENVPN_INT | awk '{print $3}' | grep -v $OPENVPN_INT | head -n 1)


# create result file
rm -f $RESULT_FILE && touch $RESULT_FILE && chmod 755 $RESULT_FILE


# put info into $RESULT_FILE
echo "$CPU, $MEMORY, $UPTIME" > $RESULT_FILE
echo "$IPLIST" >> $RESULT_FILE



#if regexp doesn't match an ip adddress in $OPENVPN_GATEWAY, then there is no active OpenVPN connection
if ! [[ $OPENVPN_GATEWAY =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        OPENVPN_GATEWAY="OVPN_GTW: NO_GTW"
        echo "DEF_GTW: $DEFAULT_GATEWAY_INT=$DEFAULT_GATEWAY_IP; OVPN_GTW: $OPENVPN_GATEWAY" >> $RESULT_FILE
        exit 0
fi
echo "DEF_GTW: $DEFAULT_GATEWAY_INT=$DEFAULT_GATEWAY_IP; OVPN_GTW: $OPENVPN_GATEWAY" >> $RESULT_FILE

#ping gateways
echo "" >> $RESULT_FILE
F_PING_HOST $DEFAULT_GATEWAY_INT $DEFAULT_GATEWAY_IP >> $RESULT_FILE
echo "PING OPENVPN GATEWAY RESULT:" >> $RESULT_FILE
echo "$PING_RESULT" >> $RESULT_FILE
echo "" >> $RESULT_FILE
F_PING_HOST $DEFAULT_GATEWAY_INT 8.8.8.8 >> $RESULT_FILE
echo "PING GOOGLE RESULT:" >> $RESULT_FILE
echo "$PING_RESULT" >> $RESULT_FILE