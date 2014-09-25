#!/bin/bash

# Copyright 2014, Cloud-ASIA Co., Ltd.
# Auther: Toshihiro Takehara aka nouphet
# All rights reserved - Do Not Redistribute

## 処理開始のメッセージ
echo "#########################################################################"
echo "LAMP環境の構成を開始します。"
echo `date`
echo "#########################################################################"


## パラメータの設定
### Set to Apache HTTP Server

### Set to MySQL Server
DB_NAME="sample-domain"
DB_ROOT_PASSWORD="P@ssw0rd"
#DB_USER_NAME="dbuser"
#DB_USER_PASSWORD="P@ssw0rd"

# ユーザのチェック
USER=`whoami`

if [ "$USER" != 'root' ]; then
    echo "rootユーザでスクリプトを実行してください。"
    echo "Press Enter to finish"
    read Enter
    exit 1
else
    echo "rootユーザです。"
    echo "このまま処理を続行します。"
    echo "Press Enter to Continue"
    read Enter
fi

echo "cd /usr/local/src/"
cd /usr/local/src/

echo "yum -y install wget ntp vim"
yum -y install wget ntp vim


echo "# disable SELinux"
echo "## SELinux 設定変更前確認"
getenforce
setenforce 0
echo "## SELinux 設定変更後確認"
getenforce
#vim /etc/sysconfig/selinux
perl -p -i.bak -e 's/enforcing/disabled/g' /etc/selinux/config

echo "# disable ip6tables"
chkconfig ip6tables off
chkconfig ip6tables --list

echo "# 時刻同期デーモンの有効化"
date
chkconfig ntpd on
chkconfig ntpd --list
/etc/init.d/ntpd start
ntpq -p
NTP_IP=`ntpq -p |grep -v remote |grep -v "=====" |head -1 |awk '{print $2}'`
/etc/init.d/ntpd stop
ntpdate $NTP_IP
/etc/init.d/ntpd start
date
#echo "Press Enter"
#read Enter


echo "ApacheとPHPをインストールします。"
yum -y install httpd php php-cli php-curl php-pear php-mysql php-imagick curl imagemagick
chkconfig httpd on
chkconfig httpd --list
/etc/init.d/httpd start

echo "iptablesを停止します。"
/etc/init.d/iptables stop
chkconfig iptables off
chkconfig iptables --list

# phpの情報一覧を出力するファイルを生成
cat << _EOT_ > /var/www/html/phpinfo.php
<?php
phpinfo();
?>
_EOT_


echo "MySQL Serverをインストールします。"
yum -y install mysql-server
chkconfig mysqld on
chkconfig mysqld --list

echo "MySQL Serverを初期設定します。"
/etc/init.d/mysqld start
# ここで初期設定スクリプトを実行
# パスワード設定などもここで。
/usr/bin/mysqladmin -u root password $DB_ROOT_PASSWORD
/usr/bin/mysqladmin -u root -p$DB_ROOT_PASSWORD -h localhost.localdomain password $DB_ROOT_PASSWORD

## 処理終了のメッセージ
echo "#########################################################################"
echo "# finishing message"
echo `date`
echo ""
echo "iptablesは停止されています。"
echo "iptablesを必要に応じて設定して下さい。"
echo ""
echo "SELinuxの設定を変更しています。"
echo "サーバをリブートして下さい。"
echo "コマンドを実行してください。 reboot"
echo "#########################################################################"
