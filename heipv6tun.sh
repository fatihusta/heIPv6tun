#!/bin/bash
# Fatih USTA - info@fatihusta.com
PROGNAME=`basename $0`
PROGPATH=`pwd`
 
#Tunnel Interface Name
TUN="6to4"
#Physical Lan interface Name
PHYSDEV="eth2"
 
#Information from the "Tunnel Details" page
#Server IPv4 Tunnel Address
SERVER_v4="216.66.80.30"
#Server IPv6 Tunnel Address
SERVER_v6="2001:db8:1f0a:d99::1"
 
#Wan interface IPv4 Address
CLIENT_v4="1.1.1.1"
#Lan interface IPv6 adress
CLIENT_v6="2001:db8:1f0a:d99::2"
 
# if you have a /48
ROUTED_48_EN="0" #yes/no (1/0)
ROUTED_48="2001:db8:7442::1"
 
ROUTED_64="2001:db8:1f0b:d99::1"
 
 
#Update dynamic ipv4 adress tunnelbroker.net
USERNAME="username"
PASSWORD="password"
TUNNELID="tunnel_id"
 
UPDATE_URL="https://$USERNAME:$PASSWORD@ipv4.tunnelbroker.net/nic/update?hostname=$TUNNELID"
 
#FW
IPT=`which iptables`
IP6T=`which ip6tables`
 
 
 
checktunnel() {
 
        tunnelcheck=`ifconfig | grep $TUN | awk '{print $1}'`
        if [ "$TUN" == "$tunnelcheck" ];
        then
                echo "tunnel already exists"
                exit 2
        fi
}
testipv6internet () {
        echo -n "Testing IPv6 Tunnel Server: "
        PINGSRV=`ping6 $SERVER_v6 -c 1`
        SRV=`echo $?`
        if [ "$SRV" != "0" ];
        then
                echo "FAILED"
        else
                echo "OK"
        fi
 
 
        echo -n "Testing IPv6 Internet: "
 
        PINGINT=`ping6 2a00:1450:4013:c00::67 -c 1`
        INT=`echo $?`
 
        if [ "$INT" != "0" ];
        then
                echo "FAILED"
        else
                echo "OK"
        fi
}
 
check_internet() {
        echo -n "Testing Internet: "
 
        CHCKINT=`ping google.com -c 1 2>> /dev/null`
        v4INT=`echo $?`
 
        if [ "$v4INT" != "0" ];
        then
            echo "Failed to internet connection"
            exit 1
        else
                echo "OK"
        fi
 
 
}
 
updateipv4() {
        echo -n "Update Dynamic IPv4 Adress: "
        IPv4DYN=`curl -s "$UPDATE_URL"`
        DYN=`echo $?`
 
        if [ "$DYN" != "0" ];
        then
                echo "FAILED"
                echo "$PROGNAME Update Dynamic IPv4 Adress: FAILED" | logger
        else
                echo "$PROGNAME Update Dynamic IPv4 Adress: OK" | logger
                echo "OK"
        fi
}
 
check_ip6tables() {
 
    if [[ -f $IP6T ]]; then
        check_IP6T=`service ip6tables status`
        check_IP6T_stats=`echo $?`
        echo $check_IP6T_stats 
    fi
}
 
add_IP4T_and_IP6T_InterfaceRules() {
 
    if [[ `check_ip6tables` == "0"  ]]; then
        $IP6T -I INPUT -s $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -I OUTPUT -s $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -I FORWARD -s $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -I INPUT -d $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -I OUTPUT -d $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -I FORWARD -d $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
    fi
 
    $IPT -I INPUT -s $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -I OUTPUT -s $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -I FORWARD -s $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -I INPUT -d $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -I OUTPUT -d $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -I FORWARD -d $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
 
}
 
delete_IP4T_and_IP6T_InterfaceRules() {
 
    if [[ `check_ip6tables` == "0"  ]]; then
        $IP6T -D INPUT -s $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -D OUTPUT -s $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -D FORWARD -s $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -D INPUT -d $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -D OUTPUT -d $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
        $IP6T -D FORWARD -d $CLIENT_v6/64 -j ACCEPT  >/dev/null 2>&1
    fi
 
    $IPT -D INPUT -s $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -D OUTPUT -s $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -D FORWARD -s $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -D INPUT -d $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -D OUTPUT -d $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
    $IPT -D FORWARD -d $CLIENT_v4 -j ACCEPT  >/dev/null 2>&1
}
 
start() {
        modprobe ipv6 2>> /dev/null
        echo -n "Starting he.net IPv6 tunnel: "
        ip tunnel add $TUN mode sit remote $SERVER_v4 local $CLIENT_v4 ttl 255 2>> /dev/null
        ip link set $TUN up 2>> /dev/null
 
        ip -6 addr add $CLIENT_v6/64 dev $TUN 2>> /dev/null
        ip -6 ro add default via $SERVER_v6 dev $TUN 2>> /dev/null
 
        ip -6 addr add $ROUTED_64/64 dev $PHYSDEV 2>> /dev/null
 
        if [ $ROUTED_48_EN == "1"  ];
        then
        ip -6 addr add $ROUTED_48/48 dev $PHYSDEV 2>> /dev/null
        fi
 
        #ip -f inet6 addr
 
        echo "Done."
        #add cron jobs update ipv4 dynamic adress
        echo 'MAILTO=""' > /etc/cron.d/$PROGNAME.cron
        echo "*/5 * * * * root $PROGPATH/$PROGNAME updateipv4" >> /etc/cron.d/$PROGNAME.cron
        echo "*/5 * * * * root $PROGPATH/$PROGNAME start" >> /etc/cron.d/$PROGNAME.cron
        CRON=`/etc/init.d/crond restart 2>> /dev/null`
 
        echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
        echo 1 > /proc/sys/net/ipv6/conf/default/forwarding
 
        add_IP4T_and_IP6T_InterfaceRules
}
 
 
stop() {
        echo -n "Stopping he.net IPv6 tunnel: "
 
        delete_IP4T_and_IP6T_InterfaceRules
 
        ip -6 addr delete $ROUTED_64/64 dev $PHYSDEV 2>> /dev/null
 
 
        ip -6 addr delete $ROUTED_48/48 dev $PHYSDEV 2>> /dev/null
 
        ip link set $TUN down 2>> /dev/null
        ip tunnel del $TUN 2>> /dev/null
 
        DELTUN=`echo $?`
 
        if [ "$DELTUN" != "0" ];
        then
                echo "FAILED. No is up tunnel"
        else
                echo "Done."
        fi
 
        rm -rf /etc/cron.d/$PROGNAME.cron
        CRON=`/etc/init.d/crond restart 2>> /dev/null`
 
        echo 0 > /proc/sys/net/ipv6/conf/all/forwarding
        echo 0 > /proc/sys/net/ipv6/conf/default/forwarding
}
restart() {
        stop
        sleep 1
        checktunnel
        check_internet
        updateipv4
        start
        testipv6internet
}
 
 
case "$1" in
 
start)
        checktunnel
        check_internet
        updateipv4
        start
        testipv6internet
        ;;
stop)
        stop
        ;;
restart)
        restart
        ;;
conntest)
        testipv6internet
        ;;
updateipv4)
        check_internet
        updateipv4
        ;;
*)
        echo "Usage"
        echo "bash $PROGNAME <start|stop|restart|conntest|updateipv4>"
esac
