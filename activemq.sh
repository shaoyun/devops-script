#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install activemq"
    exit 1
fi

cur_dir=$(pwd)

if [ ! -d "${cur_dir}/downloads" ];then
	mkdir ${cur_dir}/downloads
fi

cd ${cur_dir}/downloads

URL=http://18.138.115.170:8080/downloads/apache-activemq-5.15.11-bin.tar.gz
# URL=http://apache.mirror.iweb.ca//activemq/5.15.11/apache-activemq-5.15.11-bin.tar.gz

wget -c --progress=bar:force --prefer-family=IPv4 --no-check-certificate ${URL}
tar zxf apache-activemq-5.15.11-bin.tar.gz

cat > /lib/systemd/system/activemq.service<<\EOF
[Unit]
Description=ActiveMQ service
After=network.target

[Service]
Type=simple
Environment=JAVA_HOME=/usr/local/java/jdk1.8.0_181

PIDFile=/data/apache-activemq-5.15.11/data/activemq.pid
User=root
Group=root
ExecStart=/data/apache-activemq-5.15.11/bin/activemq start
ExecStop=/data/apache-activemq-5.15.11/bin/activemq stop

[Install]
WantedBy=multi-user.target
EOF
systemctl enable activemq
echo "Please run 'systemctl enable activemq' to start service"
