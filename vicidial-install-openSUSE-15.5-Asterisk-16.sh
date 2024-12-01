#!/bin/bash

# Vicidial Installation Script for openSUSE 15.5 with Asterisk 16

# 1. System Preparation
echo "Updating system..."
zypper refresh
zypper update -y

# 2. Install Dependencies
echo "Installing dependencies..."
zypper install -y wget curl gcc gcc-c++ make perl perl-CPAN libxml2 libxml2-devel libxslt1 libxslt-devel libnewt-devel ncurses-devel bison openssl openssl-devel libssl-devel unixODBC unixODBC-devel sox subversion git mariadb mariadb-client mariadb-tools apache2 php php-mysql php-xml php-gd php-curl

# 3. Start and Enable Apache
echo "Starting and enabling Apache..."
systemctl enable apache2
systemctl start apache2

# 4. Configure PHP
echo "Configuring PHP..."
sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php7/apache2/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /etc/php7/apache2/php.ini
sed -i 's/post_max_size = .*/post_max_size = 64M/' /etc/php7/apache2/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php7/apache2/php.ini
echo "date.timezone = \"Your/Timezone\"" >> /etc/php7/apache2/php.ini

# Restart Apache to apply PHP settings
systemctl restart apache2

# 5. Install MySQL (MariaDB)
echo "Installing and configuring MariaDB..."
zypper install -y mariadb mariadb-client
systemctl enable mariadb
systemctl start mariadb

# Secure MySQL installation
echo "Securing MySQL installation..."
mysql_secure_installation

# 6. Install Asterisk 16
echo "Installing Asterisk 16..."
cd /usr/src/
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
tar -xvzf asterisk-16-current.tar.gz
cd asterisk-16*/
./configure
contrib/scripts/install_prereq install

# Menuselect (optional: adjust manually if needed)
make menuselect

# Compile and install Asterisk
make
make install
make samples
make config
ldconfig

# Start Asterisk
systemctl enable asterisk
systemctl start asterisk

# 7. Download and Install Vicidial
echo "Installing Vicidial..."
cd /usr/src/
svn checkout svn://svn.eflo.net:3690/agc_2-X/trunk vicidial
cd vicidial
./install.pl

# 8. Configure Apache for Vicidial
echo "Configuring Apache for Vicidial..."
cat <<EOT >> /etc/apache2/conf.d/vicidial.conf
<Directory "/srv/www/htdocs/vicidial">
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOT

# Restart Apache to apply changes
systemctl restart apache2

# 9. Configure MySQL for Vicidial
echo "Setting up MySQL for Vicidial..."
mysql -u root -p <<EOF
CREATE DATABASE asterisk;
GRANT ALL PRIVILEGES ON asterisk.* TO 'cron'@'localhost' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON asterisk.* TO 'cron'@'%' IDENTIFIED BY '1234';
FLUSH PRIVILEGES;
EOF

# Import Vicidial SQL data
echo "Importing Vicidial database schema..."
cd /usr/src/vicidial
mysql -u root -p asterisk < /usr/src/vicidial/extras/MySQL_AST_CREATE_tables.sql
mysql -u root -p asterisk < /usr/src/vicidial/extras/first_server_install.sql

# 10. Install DAHDI
echo "Installing DAHDI..."
cd /usr/src/
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
tar -xvzf dahdi-linux-complete-current.tar.gz
cd dahdi-linux-complete-*
make all
make install
make config

# Generate DAHDI configuration and start service
dahdi_genconf
systemctl enable dahdi
systemctl start dahdi

# 11. Install LibPRI (Optional)
echo "Installing LibPRI (optional)..."
cd /usr/src/
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
tar -xvzf libpri-current.tar.gz
cd libpri-*
make
make install

# 12. Configure Cron Jobs for Vicidial
echo "Setting up Vicidial cron jobs..."
(crontab -l 2>/dev/null; echo "* * * * * /usr/share/astguiclient/AST_manager_listen.pl") | crontab -
(crontab -l 2>/dev/null; echo "* * * * * /usr/share/astguiclient/AST_send_listen.pl") | crontab -
(crontab -l 2>/dev/null; echo "* * * * * /usr/share/astguiclient/AST_VDauto_dial_FILL.pl --lists") | crontab -

# 13. Final Message
echo "Vicidial installation is complete! Access the Vicidial web interface at http://your-server-ip/vicidial/admin.php."
echo "Default login: 6666 / 1234"
