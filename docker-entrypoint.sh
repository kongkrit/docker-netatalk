#!/bin/bash

if [ ! -z "${AFP_USER}" ]; then
    if [ ! -z "${AFP_UID}" ]; then
        cmd="$cmd --uid ${AFP_UID}"
    fi
    if [ ! -z "${AFP_GID}" ]; then
        cmd="$cmd --gid ${AFP_GID}"
        groupadd --gid ${AFP_GID} ${AFP_USER}
    fi
    adduser $cmd --no-create-home --disabled-password --gecos '' "${AFP_USER}"
    if [ ! -z "${AFP_PASSWORD}" ]; then
        echo "${AFP_USER}:${AFP_PASSWORD}" | chpasswd
    fi
fi

if [ ! -d /media/share ]; then
  mkdir /media/share
  echo "use -v /my/dir/to/share:/media/share" > readme.txt
fi
chown "${AFP_USER}" /media/share

if [ ! -d /media/timemachine ]; then
  mkdir /media/timemachine
  echo "use -v /my/dir/to/timemachine:/media/timemachine" > readme.txt
fi
chown "${AFP_USER}" /media/timemachine

sed -i'' -e "s,%USER%,${AFP_USER:-},g" /etc/afp.conf

SEDEX="s/; share vol size limit =/vol size limit = ""$SHARE_SIZE_LIMIT""/g"
if [[ $SHARE_SIZE_LIMIT =~ ^[0-9]+$ ]] ; then
  cat /etc/afp.conf | \
  sed -E "$SEDEX" > /tmp/afpout
else
  echo "SHARE_SIZE_LIMIT isn't number"
  cp /etc/afp.conf /tmp/afpout
fi

SEDEX="s/; timemachine vol size limit =/vol size limit = ""$TIMEMACHINE_SIZE_LIMIT""/g"

if [[ $TIMEMACHINE_SIZE_LIMIT =~ ^[0-9]+$ ]] ; then
  cat /tmp/afpout | \
  sed -E "$SEDEX" > /etc/afp.conf
else
  echo "SHARE_SIZE_LIMIT isn't number"
  cp /tmp/afpout /etc/afp.conf
fi

rm -f /tmp/afpout

echo ---begin-afp.conf--
cat /etc/afp.conf
echo ---end---afp.conf--

mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-daemon --system
if [ "${AVAHI}" == "1" ]; then
    sed -i '/rlimit-nproc/d' /etc/avahi/avahi-daemon.conf
    avahi-daemon -D
else
    echo "Skipping avahi daemon, enable with env variable AVAHI=1"
fi;

exec netatalk -d
