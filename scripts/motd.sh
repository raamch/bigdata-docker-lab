#!/bin/bash

if [ "$(hostname -s)" = "ambari-server" ]; then
    NODE_LINE="★  AMBARI SERVER NODE  ★"
else
    NODE_LINE="◆  AMBARI SLAVE NODE   ◆"
fi
AGENT_SERVER=$(grep "^hostname=" /etc/ambari-agent/conf/ambari-agent.ini 2>/dev/null | cut -d'=' -f2)

printf "\n"
printf "  ╔══════════════════════════════════════════════════════╗\n"
printf "  ║          BIG DATA LAB - EDUCATIONAL                  ║\n"
printf "  ╠══════════════════════════════════════════════════════╣\n"
printf "  ║           $NODE_LINE                   ║\n"
printf "  ╠══════════════════════════════════════════════════════╣\n"
printf "  ║  %-52s║\n" "Cluster  : Ambari2.7.5,Bigtop3.2.1,PgreSQL10.23,RL8"
printf "  ║  %-52s║\n" "Hostname : $(hostname -f)"
printf "  ║  %-52s║\n" "Server   : ${AGENT_SERVER:-NOT SET}"
printf "  ║  %-52s║\n" "Timezone : $(cat /etc/timezone)"
printf "  ╠══════════════════════════════════════════════════════╣\n"
printf "  ║  %-52s║\n" "Ambari UI  : http://ambari-server:8080"
printf "  ║  %-52s║\n" "Credentials: admin / admin"
printf "  ╠══════════════════════════════════════════════════════╣\n"
printf "  ║  %-52s║\n" "Prepared by : Ram CH"
printf "  ║  %-52s║\n" "Purpose     : Educational Use Only"
printf "  ╚══════════════════════════════════════════════════════╝\n"
printf "\n"