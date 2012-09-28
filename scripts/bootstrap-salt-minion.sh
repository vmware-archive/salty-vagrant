#!/bin/sh

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

LOGFILE=/var/log/bootstrap-salt-minion.log 

log() {
    message="$@"
    echo $message
    echo $message >>$LOGFILE
}

UNAME=`uname`
if [ "$UNAME" != "Linux" ] ; then
    log "Sorry, this OS is not supported."
    exit 1
fi

set -e
trap "echo Installation failed." EXIT

if [ "$UNAME" = "Linux" ] ; then
    do_with_root() {
        if [ `whoami` = 'root' ] ; then
            RESULT=$($*)
            log $RESULT
        else
            log "Salt requires root privileges to install. Please re-run this script as root."
            exit 1
        fi
    }
 
    if [ -f /etc/lsb-release ] ; then
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
    else
        log "Unable to install. Could not detect distribution."
        exit 1
    fi

    log "OS: $OS, CODENAME: $CODENAME"

    if [ $OS = 'Ubuntu' ]; then
        if [ $DEVELOP = 1 ]; then
            do_with_root mkdir -p /etc/salt/pki
            do_with_root apt-get update
            do_with_root apt-get install -y python-software-properties
            do_with_root echo | add-apt-repository  ppa:saltstack/salt
            do_with_root apt-get update
            do_with_root apt-get install -y salt-minion git-core
            do_with_root rm -rf /usr/share/pyshared/salt*
            do_with_root rm -rf /usr/bin/salt-*
            do_with_root mkdir -p /root/git
            do_with_root rm -rf /root/git/salt
            do_with_root cd /root/git
            do_with_root git clone git://github.com/saltstack/salt.git
            do_with_root cd /root/git/salt
            do_with_root python setup.py install --install-layout=deb
        elif [ $CODENAME = 'oneiric' ]; then
            log "Installing for $OS $CODENAME."
            do_with_root apt-get update
            do_with_root apt-get -y install python-software-properties
            do_with_root add-apt-repository -y 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe'
            do_with_root add-apt-repository -y ppa:saltstack/salt
            do_with_root apt-get update
            do_with_root apt-get -y install msgpack-python salt-minion
            do_with_root add-apt-repository -y --remove 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe'
        elif [ $CODENAME = 'lucid' -o $CODENAME = 'precise' ]; then
            log "Installing for $OS $CODENAME."
            do_with_root apt-get update
            do_with_root apt-get -y install python-software-properties
            do_with_root add-apt-repository -y ppa:saltstack/salt
            do_with_root apt-get update
            do_with_root apt-get -y install salt-minion
        else
            log "Ubuntu $CODENAME is not supported."
            exit 1
        fi
    elif [ $OS = 'Debian' ]; then
        if [ $CODENAME = 'wheezy' -o $CODENAME = 'jessie' ]; then
            log "Installing for Debian Weezy/Jessie."
            do_with_root apt-get -y install salt-minion
        elif [ $CODENAME = '6.0'  ]; then
            log "Installing for Debian Squeeze."
            do_with_root echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> /etc/apt/sources.list.d/backports.list
            do_with_root apt-get update
            do_with_root apt-get -t squeeze-backports -y install salt-minion
        else
            log "Debian $CODENAME is not supported."
            exit 1
        fi

    elif [ $OS = 'Fedora' ] ; then
        log "Installing for $OS $CODENAME"
        do_with_root yum install -y salt-minion
        # Set the minion to start on reboot

    elif [ $OS = 'Redhat' ] ; then
        log "Installing for Redhat/CentOS"
        log "(this could take a while)"
        do_with_root rpm -Uvh --force http://mirrors.kernel.org/fedora-epel/6/x86_64/epel-release-6-7.noarch.rpm
        do_with_root yum update -y
        do_with_root yum -y install salt-minion --enablerepo=epel-testing
    else
        log "Unable to install. Bootstap script does not yet support $OS $CODENAME"

        exit 1
    fi

fi

log "Salt has been installed!"
trap - EXIT
