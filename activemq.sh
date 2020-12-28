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

URL=https://mirrors.bfsu.edu.cn/apache//activemq/5.16.0/apache-activemq-5.16.0-bin.tar.gz

wget -c --progress=bar:force --prefer-family=IPv4 --no-check-certificate ${URL}
tar zxf apache-activemq-5.16.0-bin.tar.gz
mv ./apache-activemq-5.16.0 /data

cat > /lib/systemd/system/activemq.service<<\EOF
[Unit]
Description=ActiveMQ service
After=network.target

[Service]
Type=simple
Environment=JAVA_HOME=/usr/local/tool/java

PIDFile=/data/apache-activemq-5.16.0/data/activemq.pid
User=root
Group=root
ExecStart=/data/apache-activemq-5.16.0/bin/activemq start
ExecStop=/data/apache-activemq-5.16.0/bin/activemq stop

[Install]
WantedBy=multi-user.target
EOF
systemctl enable activemq
echo "Please run 'systemctl start activemq' to start service"
