# devops-script

## redis的一键安装脚本

提取自军哥的lnmp一键安装脚本，自动下载、编译、安装和配置，需要wget支持，剥离了原来脚本默认对PHP的支持， 防火墙需要手动添加6379端口

iptables
```
iptables -D INPUT -p tcp --dport 6379 -j DROP
service iptables save
service iptables reload
```
firewalld
```
firewall-cmd --zone=public --add-port=6379/tcp --permanent
firewall-cmd --reload
```

## JDK一键安装脚本

由于source命令在脚本中不生效，所有需要手动执行source

```
source /etc/profile
java -version
```
