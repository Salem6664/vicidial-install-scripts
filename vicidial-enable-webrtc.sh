#!/bin/bash

echo "Install certbot for LetsEncrypt"
if [ -f /etc/redhat-release ]; then
	yum -y install certbot python2-certbot-apache mod_ssl
fi
if [ -f /etc/lsb-release ]; then
	sudo add-apt-repository ppa:certbot/certbot
	sudo apt install python-certbot-apache
fi

echo "Enter the DOMAIN NAME HERE. ***********IF YOU DONT HAVE ONE PLEASE DONT CONTINUE: "
read DOMAINNAME

wget -O /etc/httpd/conf.d/$DOMAINNAME.conf https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/DOMAINNAME.conf
sed -i s/DOMAINNAME/"$DOMAINNAME"/g /etc/httpd/conf.d/$DOMAINNAME.conf

echo "Please Enter EMAIL and Agree the Terms and Conditions "
certbot --apache -d $DOMAINNAME --agree-tos -m steve.turner@genxoutsourcing.com -n

echo "Change http.conf in Asterisk"
wget -O /etc/asterisk/http.conf https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/asterisk-http.conf
sed -i s/DOMAINNAME/"$DOMAINNAME"/g /etc/asterisk/http.conf


echo "Reloading Asterisk"
rasterisk -x reload

echo "Add DOMAINAME servers web_socket_url"
echo "%%%%%%%%%%%%%%%This Wont work if you SET root Password%%%%%%%%%%%%%%%"
mysql -e "use asterisk; update servers set web_socket_url='wss://$DOMAINNAME:8089/ws';"

echo "Add DOMAINAME system_settings webphone_url"
echo "%%%%%%%%%%%%%%%This Wont work if you SET root Password%%%%%%%%%%%%%%%"
mysql -e "use asterisk; update system_settings set webphone_url='https://phone.viciphone.com/viciphone.php';"

echo "Create WEBRTC Template"

mysql -e "use asterisk; INSERT INTO vicidial_conf_templates (template_id,template_name,template_contents,user_group) values('WEBRTC' ,'WEBRTC Default Phones'.'','---ALL---';"

mysql -e "use asterisk; update vicidial_conf_templates set template_contents='type=friend 
host=dynamic
encryption=yes
avpf=yes
icesupport=yes
directmedia=no
transport=wss
force_avp=yes
dtlsenable=yes
dtlsverify=no
dtlscertfile=/etc/letsencrypt/live/$DOMAINNAME/cert.pem
dtlsprivatekey=/etc/letsencrypt/live/$DOMAINNAME/privkey.pem
dtlssetup=actpass
rtcp_mux=yes' where template_id='WEBRTC';"

echo "update the Phone tables to set is_webphone to Y default"
mysql -e "use asterisk; ALTER TABLE phones MODIFY COLUMN is_webphone ENUM('Y','N','Y_API_LAUNCH') default 'Y';"
mysql -e "use asterisk; update phones set template_id='WEBRTC';"

#Update the 6666 user permissions
#echo "VICIDIAL 6666 PASSWORD"
#read 6666pass
#mysql -e "use asterisk; UPDATE `vicidial_users` VALUES (1,'6666','$6666pass','Admin',9,'ADMIN','','','1','1','1','1','1','1','1','1','1','1','1','1','0','1','1','','1','0','0','1','1','1','1','0','1','1','1','1','1','1','1','1','1','1','1','1','DISABLED','NOT_ACTIVE','0',1,'0','0','0','1','1','1','NOT_ACTIVE','0','1','1','Y','0','1','DISABLED','1','0','1','1','','','','0','0','','','','','','','DISABLED','1','1','0','0','N','NOT_ACTIVE','1','1','1','1','1','1','1','1','1','NOT_ACTIVE','1','1','0','0','0','0',0,'2021-10-16 10:21:11','112.205.228.217','','1',0,'1',-1,'0','default English','0','0','0',' ALL_FUNCTIONS ','NONE','0','0','0','0','1','',-1,'0','0','0','0',-1,'0','1',0,0,'DISABLED','DISABLED','NOT_ACTIVE','','0','','',-1,'','','NOT_ACTIVE','DISABLED'),(2,'VDAD','donotedit','Outbound Auto Dial',1,'ADMIN',NULL,NULL,'0','0','0','0','0','0','0','0','0','0','0','0','0','0','1',NULL,'1','0','0','1','1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','DISABLED','NOT_ACTIVE','0',1,'0','0','0','0','0','0','NOT_ACTIVE','0','0','0','N','0','0','DISABLED','0','0','0','0','','','','0','1','','','','','',NULL,'DISABLED','0','1','0','0','N','NOT_ACTIVE','0','0','0','0','0','0','0','0','0','NOT_ACTIVE','0','1','0','0','0','0',0,'2001-01-01 00:00:01','','','1',0,'0',-1,'0','default English','0','0','0',' ALL_FUNCTIONS ','NONE','0','0','0','0','0','',-1,'0','0','0','0',-1,'0','0',0,0,'DISABLED','DISABLED','NOT_ACTIVE',NULL,'0',NULL,NULL,-1,'','','NOT_ACTIVE','DISABLED'),(3,'VDCL','donotedit','Inbound No Agent',1,'ADMIN',NULL,NULL,'0','0','0','0','0','0','0','0','0','0','0','0','0','0','1',NULL,'1','0','0','1','1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','DISABLED','NOT_ACTIVE','0',1,'0','0','0','0','0','0','NOT_ACTIVE','0','0','0','N','0','0','DISABLED','0','0','0','0','','','','0','1','','','','','',NULL,'DISABLED','0','1','0','0','N','NOT_ACTIVE','0','0','0','0','0','0','0','0','0','NOT_ACTIVE','0','1','0','0','0','0',0,'2001-01-01 00:00:01','','','1',0,'0',-1,'0','default English','0','0','0',' ALL_FUNCTIONS ','NONE','0','0','0','0','0','',-1,'0','0','0','0',-1,'0','0',0,0,'DISABLED','DISABLED','NOT_ACTIVE',NULL,'0',NULL,NULL,-1,'','','NOT_ACTIVE','DISABLED');"

