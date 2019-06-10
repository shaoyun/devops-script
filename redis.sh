#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

cur_dir=$(pwd)

if [ ! -d "${cur_dir}/src" ];then
	mkdir ${cur_dir}/src
fi

Redis_Stable_Ver='redis-5.0.5'

Get_OS_Bit()
{
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}

Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux" /etc/issue || grep -Eq "Red Hat Enterprise Linux" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        DISTRO='Amazon'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
        PM='apt'
    elif grep -Eqi "Mint" /etc/issue || grep -Eq "Mint" /etc/*-release; then
        DISTRO='Mint'
        PM='apt'
    elif grep -Eqi "Kali" /etc/issue || grep -Eq "Kali" /etc/*-release; then
        DISTRO='Kali'
        PM='apt'
    else
        DISTRO='unknow'
    fi
    Get_OS_Bit
}

Make_Install()
{
    make -j `grep 'processor' /proc/cpuinfo | wc -l`
    if [ $? -ne 0 ]; then
        make
    fi
    make install
}

Tar_Cd()
{
    local FileName=$1
    local DirName=$2
    cd ${cur_dir}/src
    [[ -d "${DirName}" ]] && rm -rf ${DirName}
    echo "Uncompress ${FileName}..."
    tar zxf ${FileName}
    if [ -n "${DirName}" ]; then
        echo "cd ${DirName}..."
        cd ${DirName}
    fi
}

Download_Files()
{
    local URL=$1
    local FileName=$2
    if [ -s "${FileName}" ]; then
        echo "${FileName} [found]"
    else
        echo "Notice: ${FileName} not found!!!download now..."
        wget -c --progress=bar:force --prefer-family=IPv4 --no-check-certificate ${URL}
    fi
}

StartUp()
{
    init_name=$1
    echo "Add ${init_name} service at system startup..."
    if [ "$PM" = "yum" ]; then
        chkconfig --add ${init_name}
        chkconfig ${init_name} on
    elif [ "$PM" = "apt" ]; then
        update-rc.d -f ${init_name} defaults
    fi
}

Remove_StartUp()
{
    init_name=$1
    echo "Removing ${init_name} service at system startup..."
    if [ "$PM" = "yum" ]; then
        chkconfig ${init_name} off
        chkconfig --del ${init_name}
    elif [ "$PM" = "apt" ]; then
        update-rc.d -f ${init_name} remove
    fi
}

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Press_Start()
{
    echo ""
    Echo_Green "Press any key to start...or Press Ctrl+c to cancel"
    OLDCONFIG=`stty -g`
    stty -icanon -echo min 1 time 0
    dd count=1 2>/dev/null
    stty ${OLDCONFIG}
}


Install_Redis()
{
    echo "====== Installing Redis ======"
    echo "Install ${Redis_Stable_Ver} Stable Version..."
    Press_Start

    cd ${cur_dir}/src
    if [ -s /usr/local/redis/bin/redis-server ]; then
        echo "Redis server already exists."
    else
        Download_Files http://download.redis.io/releases/${Redis_Stable_Ver}.tar.gz ${Redis_Stable_Ver}.tar.gz
        Tar_Cd ${Redis_Stable_Ver}.tar.gz ${Redis_Stable_Ver}

        if [ "${Is_64bit}" = "y" ] ; then
            make PREFIX=/usr/local/redis install
        else
            make CFLAGS="-march=i686" PREFIX=/usr/local/redis install
        fi
        mkdir -p /usr/local/redis/etc/
        \cp redis.conf  /usr/local/redis/etc/
        sed -i 's/daemonize no/daemonize yes/g' /usr/local/redis/etc/redis.conf
        if ! grep -Eqi '^bind[[:space:]]*127.0.0.1' /usr/local/redis/etc/redis.conf; then
            sed -i 's/^# bind 127.0.0.1/bind 127.0.0.1/g' /usr/local/redis/etc/redis.conf
        fi
        sed -i 's#^pidfile /var/run/redis_6379.pid#pidfile /var/run/redis.pid#g' /usr/local/redis/etc/redis.conf
        cd ../
        rm -rf ${cur_dir}/src/${Redis_Stable_Ver}
    fi

    \cp ${cur_dir}/init.d/init.d.redis /etc/init.d/redis
    chmod +x /etc/init.d/redis
    echo "Add to auto startup..."
    StartUp redis
    /etc/init.d/redis start

    if [ -s /usr/local/redis/bin/redis-server ]; then
        Echo_Green "====== Redis install completed ======"
        Echo_Green "Redis installed successfully, enjoy it!"
    else
        Echo_Red "Redis install failed!"
    fi
}

Uninstall_Redis()
{
    echo "You will uninstall Redis..."
    Press_Start
    /etc/init.d/redis stop
    Remove_StartUp redis
    echo "Delete Redis files..."
    rm -rf /usr/local/redis
    rm -rf /etc/init.d/redis
    Echo_Green "Uninstall Redis completed."
}

Redis_Op_Selection()
{
    if [ -z ${SelectOp} ]; then
        echo "==========================="

        SelectOp="1"
        Echo_Yellow "What do you want?"
        echo "1: Install Redis (Default)"
        echo "2: Uninstall Redis"
        read -p "Enter your choice (1, 2): " SelectOp
    fi

    case "${SelectOp}" in
    1)
        echo "You will install Redis."
        ;;
    2)
        echo "You will uninstall Redis"
        ;;
    *)
        echo "No input, exit."
        exit 1
    esac

    if [ "${SelectOp}" =  "1" ]; then
		Install_Redis
    elif [ "${SelectOp}" =  "2" ]; then
    	Uninstall_Redis
    fi
}

Get_Dist_Name
Redis_Op_Selection
