#!/bin/sh

# Setup logging
if [ "$SELF_LOGGING" != "1" ] ; then
    PIPE=tmp.fifo
    mkfifo $PIPE

    # Keep PID of this process
    SELF_LOGGING=1 sh $0 $* >$PIPE &
    PID=$!

    tee /var/log/bootstrap-salt-minion.log <$PIPE &

    # Safe to rm pipe because the child processes have references to it
    rm $PIPE    
    wait $PID

    # Return same error code as original process
    exit $?
fi

usage()
{
cat << EOF
usage: $0 options

This script run the test1 or test2 over a machine.

OPTIONS:
   -h      Show this message
   -d      Install development version instead of stable
EOF
}

DEVELOP=0
while getopts “d” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         d)
             DEVELOP=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done


UNAME=`uname`
if [ "$UNAME" != "Linux" ] ; then
    echo "Sorry, OS $UNAME is not supported."
    exit 1
else
    set -e
    trap "echo Installation failed." EXIT
 
    if [ -f /etc/lsb-release ] || [ -f /usr/bin/lsb_release ]; then
        OS=$(lsb_release -si)
        CODENAME=$(lsb_release -sc)
    elif [ -f /etc/debian_version ] ; then
        OS=Debian
        CODENAME=$(cat /etc/debian_version)
    elif [ -f /etc/fedora-release ] ; then
        OS=Fedora
        CODENAME=$(cat /etc/fedora-release)
    elif [ -f /etc/redhat-release ] ; then
        OS="Redhat"
        CODENAME=$(cat /etc/redhat-release)
    elif [ -f /etc/arch-release ] ; then
        OS="Arch"
        CODENAME=$(cat /etc/arch-release)
    else
        echo "Unable to install. Could not detect distribution."
        exit 1
    fi

    echo "OS: $OS, CODENAME: $CODENAME"

    if [ $OS = 'Ubuntu' ]; then
        if [ $DEVELOP = 1 ]; then
            mkdir -p /etc/salt/pki
            apt-get update
            apt-get install -y python-software-properties
            echo | add-apt-repository  ppa:saltstack/salt
            apt-get update
            apt-get install -y salt-minion git-core
            rm -rf /usr/share/pyshared/salt*
            rm -rf /usr/bin/salt-*
            mkdir -p /root/git
            rm -rf /root/git/salt
            cd /root/git
            git clone git://github.com/saltstack/salt.git
            cd /root/git/salt
            python setup.py install --install-layout=deb
        elif [ $CODENAME = 'oneiric' ]; then
            echo "Installing for $OS $CODENAME."
            apt-get update
            apt-get -y install python-software-properties
            add-apt-repository -y 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe'
            add-apt-repository -y ppa:saltstack/salt
            apt-get update
            apt-get -y install msgpack-python salt-minion
            add-apt-repository -y --remove 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe'
        elif [ $CODENAME = 'lucid' -o $CODENAME = 'precise' ]; then
            echo "Installing for $OS $CODENAME."
            apt-get update
            apt-get -y install python-software-properties
            add-apt-repository -y ppa:saltstack/salt
            apt-get update
            apt-get -y install salt-minion
        else
            echo "Ubuntu $CODENAME is not supported."
            exit 1
        fi
    elif [ $OS = 'Debian' ]; then
        if [ $CODENAME = 'wheezy' -o $CODENAME = 'jessie' ]; then
            echo "Installing for Debian Weezy/Jessie."
            apt-get -y install salt-minion
        elif [ $CODENAME = 'squeeze'  ]; then
            echo "Installing for Debian Squeeze."
            echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> /etc/apt/sources.list.d/backports.list
            apt-get update
            apt-get -t squeeze-backports -y install salt-minion
        else
            echo "Debian $CODENAME is not supported."
            exit 1
        fi

        if [ $DEVELOP = 1 ]; then
            rm -rf /usr/share/pyshared/salt*
            rm -rf /usr/bin/salt-*
            mkdir -p /root/git
            rm -rf /root/git/salt
            cd /root/git
            git clone git://github.com/saltstack/salt.git
            cd /root/git/salt
            python setup.py install --install-layout=deb
            cp conf/salt/minion.template /etc/salt/minion
        fi
    elif [ $OS = 'Fedora' ] ; then
        if [ $DEVELOP = 1 ]; then
            yum install -y salt-minion git
            echo 'Installed Salt'
            rm -rf /usr/lib/python/site-packages/salt*
            rm -rf /usr/bin/salt-*
            mkdir -p /root/git
            cd /root/git
            git clone git://github.com/saltstack/salt.git
            cd salt
            python setup.py install
        else
            echo "Installing for $OS $CODENAME"
            yum install -y salt-minion
        fi

    elif [ $OS = 'Redhat' ] ; then
        if [ $DEVELOP = 1 ] ; then
            rpm -Uvh --force http://mirrors.kernel.org/fedora-epel/6/x86_64/epel-release-6-7.noarch.rpm
            yum -y install salt-minion git --enablerepo epel-testing
            rm -rf /usr/lib/python/site-packages/salt*
            rm -rf /usr/bin/salt-*
            mkdir -p /root/git
            cd /root/git
            git clone git://github.com/saltstack/salt.git
            cd salt
            python setup.py install
        else
            echo "Installing for Redhat/CentOS"
            rpm -Uvh --force http://mirrors.kernel.org/fedora-epel/6/x86_64/epel-release-6-7.noarch.rpm
            yum update -y
            yum -y install salt-minion --enablerepo=epel-testing
        fi
    elif [ $OS = 'Arch' ] ; then
        echo '[salt]
        Server = http://red45.org/archlinux
        ' >> /etc/pacman.conf
        pacman -Syu --noconfirm salt
    else
        echo "Unable to install. Salt bootstrap does not yet support $OS $CODENAME"
        exit 1
    fi

fi

echo "Salt has been installed!"
trap - EXIT
