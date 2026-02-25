#!/bin/bash
set -e

AGENT_INI=/etc/ambari-agent/conf/ambari-agent.ini

# Set timezone dynamically if overridden at runtime
if [ -n "$TZ" ]; then
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
    echo "$TZ" > /etc/timezone
fi

# Set FQDN properly
MYHOST=$(hostname -s)
MYFQDN="${MYHOST}.ambari.local"

# Set hostname to FQDN
echo $MYFQDN > /etc/hostname
hostname $MYFQDN

# Write clean /etc/hosts
cat > /etc/hosts << HOSTSEOF
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
10.10.0.10  ambari-server.ambari.local  ambari-server
10.10.0.11  ambari-s1.ambari.local      ambari-s1
10.10.0.12  ambari-s2.ambari.local      ambari-s2
10.10.0.13  ambari-s3.ambari.local      ambari-s3
HOSTSEOF

# Inject Ambari Server hostname into agent config
if [ -z "$AMBARI_SERVER" ]; then
    echo "WARNING: AMBARI_SERVER not set - agent not configured"
else
    echo "Configuring agent to connect to: $AMBARI_SERVER"
    sed -i "s/^hostname=.*/hostname=${AMBARI_SERVER}/" "$AGENT_INI"
    echo "Done."
fi

# Kernel tuning
setenforce 0 2>/dev/null || true
echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
echo never > /sys/kernel/mm/transparent_hugepage/defrag  2>/dev/null || true
sysctl -w vm.swappiness=10 2>/dev/null || true

# Hand over to systemd - it will auto-start ambari-agent
exec /sbin/init