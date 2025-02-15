#!/bin/bash

# Variabel tab
tab=$'\t'

# ==========================
# KONFIGURASI DNS SERVER BIND9
# ==========================

# Melakukan instalasi bind9, dnsutils
echo [INFO] "Memulai instalasi BIND9, dnsutils, dan konfigurasi zona untuk Debian 10.7"
apt install bind9 dnsutils -y
echo [INFO] "Instalasi BIND9 dan dnsutils selesai."

# Menyalin file template untuk zona forward dan reverse
echo [INFO] "Menyalin file template untuk zona forward dan reverse"
cp /etc/bind/db.local /etc/bind/reza.fwd
cp /etc/bind/db.127 /etc/bind/reza.rev
echo [INFO] "File template zona forward dan reverse berhasil disalin."

# Konfigurasi zona forward dan reverse
echo [INFO] "Mengedit file reza.fwd."
sed -i 's/localhost/fahresi.my.id/g' /etc/bind/reza.fwd
sed -i 's/127.0.0.1/172.16.18.2/g' /etc/bind/reza.fwd
sed -i '14d' /etc/bind/reza.fwd
echo "www${tab}IN${tab}A${tab}172.16.18.2" >>   /etc/bind/reza.fwd
echo "ftp${tab}IN${tab}A${tab}172.16.18.2" >>   /etc/bind/reza.fwd
echo "mail${tab}IN${tab}A${tab}172.16.18.2" >>   /etc/bind/reza.fwd
echo "@${tab}IN${tab}MX${tab}10 mail.fahresi.my.id." >>   /etc/bind/reza.fwd
echo [INFO] "Konfigurasi zona forward selesai."

# Konfigurasi zona reverse
echo [INFO] "Mengedit file reza.rev."
sed -i 's/localhost/fahresi.my.id/g' /etc/bind/reza.rev
sed -i 's/1.0.0/2/g' /etc/bind/reza.rev
echo [INFO] "Konfigurasi zona reverse selesai."

# Membuat file backup
echo [INFO] "Membuat file backup."
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
echo [INFO] "File backup berhasil dibuat."

# Konfigurasi named.conf.local
echo [INFO] "Mengedit file named.conf.local."
echo "zone \"fahresi.my.id\" {
${tab}type master;
${tab}file \"/etc/bind/reza.fwd\";
};

zone \"18.16.172.in-addr.arpa\" {
${tab}type master;
${tab}file \"/etc/bind/reza.rev\";
};" >> /etc/bind/named.conf.local
echo [INFO] "Konfigurasi named.conf.local selesai."

# Konfigurasi named.conf.options
echo [INFO] "Mengedit file named.conf.options."
sed -i $"s/dnssec-validation auto;/#dnssec-validation auto;/" /etc/bind/named.conf.options
sed -i $"16a\\${tab}forwarders {\n${tab}172.16.18.2;\n${tab}10.0.0.2;\n${tab}118.98.44.10;\n${tab}118.98.44.50;\n${tab}};\n" /etc/bind/named.conf.options
sed -i $"29i\\${tab}dnssec-validation yes;\n${tab}dnssec-enable yes;" /etc/bind/named.conf.options
sed -i $"31a\\${tab}listen-on { any; };" /etc/bind/named.conf.options
echo [INFO] "Konfigurasi named.conf.options selesai."

# Melakukan restart bind9
echo [INFO] "Restarting BIND9"
systemctl restart bind9
echo [INFO] "BIND9 telah di-restart."

# Konfigurasi DNS Server telah selesai
echo [INFO] "Konfigurasi DNS Server telah selesai."

# ==========================
# KONFIGURASI WEB SERVER APACHE2
# ==========================

# Melakukan instalasi apache2
echo [INFO] "Memulai instalasi Apache2 untuk Debian 10.7"
apt install apache2 -y
echo [INFO] "Instalasi Apache2 selesai."

# Menyalin file template 000-default.conf
echo [INFO] "Menyalin file template 000-default.conf ke reza.conf"
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/reza.conf
echo [INFO] "File template 000-default.conf berhasil disalin."

# Melakukan konfigurasi reza.conf
echo [INFO] "Mengedit file reza.conf."
sed -i "s|/var/www/html|/var/www/html/reza_wp|g" /etc/apache2/sites-available/reza.conf
sed -i $"10a\\\n${tab}ServerName fahresi.my.id\n${tab}ServerAlias www.fahresi.my.id" /etc/apache2/sites-available/reza.conf
echo [INFO] "Konfigurasi reza.conf selesai."

# Melakukan copy file default untuk web mail
echo [INFO] "Menyalin file default untuk web mail."
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/mail.conf
echo [INFO] "File default untuk web mail berhasil disalin."

# Melakukan konfigurasi mail.conf
echo [INFO] "Mengedit file mail.conf."
sed -i "s|/var/www/html|/var/lib/roundcube|g" /etc/apache2/sites-available/mail.conf
sed -i $"10a\\\n${tab}ServerName mail.fahresi.my.id" /etc/apache2/sites-available/mail.conf
echo [INFO] "Konfigurasi mail.conf selesai."

# Menonaktifkan file 000-default.conf
echo [INFO] "File 000-default.conf akan dinonaktifkan"
a2dissite 000-default.conf
echo [INFO] "File 000-default.conf berhasil dinonaktifkan"

# Mengaktifkan file reza.conf & mail.conf
echo [INFO] "File reza.conf & mail.conf akan diaktifkan"
a2ensite reza.conf
a2ensite mail.conf
echo [INFO] "File reza.conf & mail.conf berhasil diaktifkan"

# Restart apache2
echo [INFO] "Restarting Apache2"
/etc/init.d/apache2 restart
echo [INFO] "Apache2 restarted."

# ==========================
# PENGUNDUHAN FILE WORDPRESS
# ==========================

# Melakukan pengunduhan file wordpress
echo [INFO] "Memulai pengunduhan file wordpress"
wget -P /var/www/html/ wordpress.org/latest.zip 
echo [INFO] "Pengunduhan file wordpress selesai"

# Melakukan rename file wordpress
echo [INFO] "Memulai rename file wordpress"
apt install zip -y
cd /var/www/html
unzip latest.zip
mv wordpress reza_wp
cd
echo [INFO] "Rename file wordpress selesai"

# Melakukan instalasi php
echo [INFO] "Memulai instalasi PHP"
apt install php7.3 php-cgi php-gd php-mbstring php-xml php-pear php-common php-curl php-cli php-mysql -y
apt install libapache2-mod-php -y
echo [INFO] "Instalasi PHP selesai"

# Melakukan perbaikan instalasi php
echo [INFO] "Memulai perbaikan instalasi PHP"
apt --fix-broken install -y
echo [INFO] "Perbaikan instalasi PHP selesai"

# Pemberian hak akses pada folder reza_wp
echo [INFO] "Memberikan hak akses pada folder reza_wp"
chown -R www-data:www-data /var/www/html/reza_wp
chmod 755 /var/www/html/reza_wp
echo [INFO] "Pemberian hak akses pada folder reza_wp selesai"

# ==========================
# INSTALASI MARIADB SERVER
# ==========================

# Penginstallan expect
echo [INFO] "Memulai instalasi expect"
apt install expect -y
echo [INFO] "Instalasi expect selesai."

# Melakukan instalasi mariadb-server mariadb-client
echo [INFO] "Memulai instalasi MariaDB Server dan MariaDB Client"
apt install mariadb-server mariadb-client -y
echo [INFO] "Instalasi MariaDB Server dan MariaDB Client selesai."

# Menjalankan mysql_secure_installation secara otomatis
echo "[INFO] Menjalankan mysql_secure_installation secara otomatis"
expect <<EOF
set timeout 10

spawn mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "tkjbisa\r"

expect "Change the root password?*"
send "n\r"

expect "Remove anonymous users?*"
send "Y\r"

expect "Disallow root login remotely?*"
send "Y\r"

expect "Remove test database and access to it?*"
send "Y\r"

expect "Reload privilege tables now?*"
send "Y\r"

expect eof
EOF
echo "[INFO] mysql_secure_installation selesai"

# ==========================
# PEMBUAT USER DAN DATABASE
# ==========================

# Pembuat user dan database
echo [INFO] "Membuat user dan database WordPress"
mysql <<EOF
CREATE DATABASE reza_db;
CREATE USER 'reza'@'localhost' IDENTIFIED BY 'tkjbisa';
GRANT ALL ON reza_db.* TO 'reza'@'localhost' IDENTIFIED BY 'tkjbisa';
FLUSH PRIVILEGES;
EXIT
EOF
echo [INFO] "User dan database Wordpress berhasil dibuat."

# ==========================
# KONFIGURASI MAIL SERVER POSTFIX & DOVECOT
# ==========================

# Melakukan instalasi postfix dan dovecot
echo [INFO] "Memulai instalasi Postfix dan Dovecot"
apt install postfix dovecot-imapd dovecot-pop3d -y
echo [INFO] "Instalasi Postfix dan Dovecot selesai."

# Konfigurasi postfix
echo [INFO] "Mengedit file main.cf"
sed -i "/^myhostname =/c\myhostname = mail.fahresi.my.id" /etc/postfix/main.cf
sed -i "/^mydestination =/c\mydestination = localhost, mail.fahresi.my.id, fahresi.my.id" /etc/postfix/main.cf
sed -i "/^mynetworks =/c\mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 0.0.0.0/0 172.16.18.0/28" /etc/postfix/main.cf
echo "home_mailbox = Maildir/" >> /etc/postfix/main.cf
echo [INFO] "Konfigurasi main.cf selesai."

# Pembuatakn direktori Maildir
echo [INFO] "Membuat direktori Maildir"
maildirmake.dovecot /etc/skel/Maildir
echo [INFO] "Direktori Maildir berhasil dibuat."

# Konfigurasi dovecot
echo [INFO] "Mengedit file 10-mail.conf"
sed -i "s|mbox:~/mail:INBOX=/var/mail/%u|maildir:~/Maildir|" /etc/dovecot/conf.d/10-mail.conf
echo [INFO] "Konfigurasi 10-mail.conf selesai."

# Konfigurasi 10-auth.conf
echo [INFO] "Mengedit file 10-auth.conf"
sed -i "s|#disable_plaintext_auth = yes|disable_plaintext_auth = no|" /etc/dovecot/conf.d/10-auth.conf
sed -i "s|auth_mechanisms = plain|auth_mechanisms = plain login|" /etc/dovecot/conf.d/10-auth.conf
echo [INFO] "Konfigurasi 10-auth.conf selesai."

# Restart postfix dan dovecot
echo [INFO] "Restarting Postfix dan Dovecot"
systemctl restart postfix
systemctl restart dovecot
echo [INFO] "Postfix dan Dovecot telah di-restart."

# ==========================
# MEMBUAT USER BARU
# ==========================

# Nama user dan password
echo [INFO] "Membuat user dengan home directory dan shell bash"
username="siswa"
password="tkjbisa"

# Membuat user dengan home directory dan shell bash
useradd -m -s /bin/bash "$username"

# Mengatur password untuk user (dengan chpasswd)
echo "$username:$password" | chpasswd
echo [INFO] "User berhasil dibuat dengan home directory dan shell bash"

# Membuat user kedua 
echo [INFO] "Membuat user dengan home directory dan shell bash"
username="guru"
password="tkjbisa"

# Membuat user dengan home directory dan shell bash
useradd -m -s /bin/bash "$username"

# Mengatur password untuk user (dengan chpasswd)
echo "$username:$password" | chpasswd
echo [INFO] "User berhasil dibuat dengan home directory dan shell bash"


# ==========================
# KONFIGURASI WEBMAIL ROUNDCUBE
# ==========================

# Melakukan instalasi roundcube
echo [INFO] "Memulai instalasi Roundcube"
apt install roundcube -y
echo [INFO] "Instalasi Roundcube selesai."

# Konfigurasi roundcube
echo [INFO] "Mengedit file config.inc.php"
sed -i "s/\(\$config\['default_host'\] = \)'';/\1'fahresi.my.id';/" /etc/roundcube/config.inc.php
sed -i "s/\(\$config\['smtp_server'\] = \)'localhost';/\1'fahresi.my.id';/" /etc/roundcube/config.inc.php
sed -i "s/\(\$config\['smtp_user'\] = \)'%u';/\1'';/" /etc/roundcube/config.inc.php
sed -i "s/\(\$config\['smtp_pass'\] = \)'%p';/\1'';/" /etc/roundcube/config.inc.php
sed -i "s/\(\$config\['product_name'\] = \)'Roundcube Webmail';/\1'Reza Fahresi Webmail';/" /etc/roundcube/config.inc.php
echo [INFO] "Konfigurasi config.inc.php selesai."

# ==========================
# Memberi hak akses pada db roundcube
# ==========================

# Memberi hak akses pada db roundcube
echo [INFO] "Memberi hak akses pada db roundcube"
mysql <<EOF
GRANT ALL ON roundcube.* TO 'roundcube'@'localhost' IDENTIFIED BY 'tkjbisa';
FLUSH PRIVILEGES;
EXIT
EOF
echo [INFO] "Hak akses pada db roundcube telah diberikan."

# ==========================
#  KONFIGURASI FTP SERVER PROFTPD
# ==========================

# Melakukan instalasi proftpd
echo [INFO] "Memulai instalasi ProFTPD"
apt install proftpd -y
echo [INFO] "Instalasi ProFTPD selesai."

# Melakukan perbaikan instalasi proftpd
echo [INFO] "Memulai perbaikan instalasi ProFTPD"
apt --fix-broken install -y
echo [INFO] "Perbaikan instalasi ProFTPD selesai."

# Konfigurasi proftpd
echo [INFO] "Mengedit file proftpd.conf"
sed -i 's/^\(ServerName[[:space:]]*\)"Debian"/\1"ftp.fahresi.my.id"/' /etc/proftpd/proftpd.conf
sed -i "s|# DefaultRoot|DefaultRoot|" /etc/proftpd/proftpd.conf
sed -i "s|# RequireValidShell|RequireValidShell|" /etc/proftpd/proftpd.conf
sed -i "s/^\(User[[:space:]]*\)proftpd/\1reza/" /etc/proftpd/proftpd.conf
sed -i "s/^\(Group[[:space:]]*\)nogroup/\1www-data/" /etc/proftpd/proftpd.conf
echo [INFO] "Konfigurasi proftpd.conf selesai."

# Mengubah group user proftpd
echo [INFO] "Mengubah group user proftpd"
adduser reza www-data
chmod 755 /home/reza
chown reza:www-data /home/reza
echo [INFO] "Group user proftpd telah diubah."

# Restart proftpd
echo [INFO] "Restarting ProFTPD"
systemctl restart proftpd
echo [INFO] "ProFTPD restarted."

# ==========================
# Melakukan restart semua service
# ==========================

# Restart semua service
echo [INFO] "Restarting semua service"
systemctl restart bind9
systemctl restart apache2
systemctl restart postfix
systemctl restart dovecot
systemctl restart proftpd
echo [INFO] "Semua service telah di-restart."
echo [INFO] "Harap rubah IP & resolv.conf dengan ip 172.16.18.2"
echo [INFO] "Konfigurasi server telah selesai."