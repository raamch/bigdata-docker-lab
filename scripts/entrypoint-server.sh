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

# Server agent points to itself
echo "Configuring agent to connect to self: $MYFQDN"
sed -i "s/^hostname=.*/hostname=${MYFQDN}/" "$AGENT_INI"

# Kernel tuning
setenforce 0 2>/dev/null || true
echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
echo never > /sys/kernel/mm/transparent_hugepage/defrag  2>/dev/null || true
sysctl -w vm.swappiness=10 2>/dev/null || true

# First time setup
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
    cat > /etc/rc.d/init.d/ambari-setup << 'EOF'
#!/bin/bash
# chkconfig: 2345 99 01
# description: Ambari Server first time setup
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
    sleep 10
    ambari-server setup -s -j /usr/lib/jvm/java-1.8.0-openjdk
    ambari-server install-mpack --mpack=/usr/lib/bigtop-ambari-mpack/bgtp-ambari-mpack-1.0.0.0-SNAPSHOT-bgtp-ambari-mpack.tar.gz
    # Fix repoinfo.xml
    cat > /var/lib/ambari-server/resources/mpacks/bgtp-ambari-mpack-1.0.0.0-SNAPSHOT/stacks/BGTP/1.0/repos/repoinfo.xml << 'REPOEOF'
<?xml version="1.0"?>
<reposinfo>
  <os family="redhat7">
    <repo>
      <baseurl>http://repos.bigtop.apache.org/releases/3.2.1/rockylinux/8/x86_64</baseurl>
      <repoid>BGTP-1.0</repoid>
      <reponame>BGTP</reponame>
    </repo>
  </os>
</reposinfo>
REPOEOF
    ambari-server start
    systemctl disable ambari-setup
fi
EOF
    chmod +x /etc/rc.d/init.d/ambari-setup
    chkconfig --add ambari-setup
    systemctl enable ambari-setup
fi

# Enable Ambari Server autostart
systemctl enable ambari-server

# Hand over to systemd
exec /sbin/init