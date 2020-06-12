#!/bin/bash -x
#
# Install packages
yum update -y
yum install -y stress-ng git nginx nfs-utils
yum install -y oracle-release-el7
yum install -y oracle-instantclient19.6-sqlplus.x86_64 oracle-instantclient19.6-devel.x86_64
yum install -y nodejs oracle-nodejs-release-el7 oracle-release-el7
#
# Install NPM packages (for NODE.JS)
/bin/npm install oracledb@3.1.2
/bin/npm install -g forever
/bin/npm install -g forever-service
#
# Enable firewall and open for HTTP (port 80)
firewall-offline-cmd --add-service=http
systemctl enable firewalld
systemctl restart firewalld
#
#mv /usr/lib/oracle/19.3/client64/lib/network/admin /usr/lib/oracle/19.3/client64/lib/network/admin_OLD
#
# Create a service with my node.js application
forever-service install server --script /home/opc/nodejs-blog-tutorial/index.js
service server start
#
# Adjust NGINX config file
PUBLICIP=`oci-public-ip -g`
PRIVATEIP=`oci-metadata | grep -i 'Private IP' | awk '{print $4}'`
TAB=`printf '\t\t\t'`
cd /etc/nginx
cp nginx.conf nginx.conf_ORI
\cp nginx.conf_ORI nginx.conf
sed -i -e '/^[ \t]*#/d' nginx.conf
sed -i "s/server_name/server_name ${PUBLICIP}; #/g" nginx.conf
echo "${TAB}proxy_pass http://${PRIVATEIP}:3050;" > /tmp/add.txt
echo "${TAB}proxy_http_version 1.1;" >> /tmp/add.txt
echo "${TAB}proxy_set_header Upgrade \$http_upgrade;" >> /tmp/add.txt
echo "${TAB}proxy_set_header Connection 'upgrade';" >> /tmp/add.txt
echo "${TAB}proxy_set_header Host \$host;" >> /tmp/add.txt
echo "${TAB}proxy_cache_bypass \$http_upgrade;" >> /tmp/add.txt
sed -i '/location\s\/\s{/r /tmp/add.txt' nginx.conf
#
# Enable and start NGINX
systemctl enable nginx
systemctl start nginx
setsebool -P httpd_can_network_relay on
setsebool -P httpd_can_network_connect on