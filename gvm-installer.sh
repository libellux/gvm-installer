#!/bin/bash
#
# Libellux: Up and Running
# Greenbone Vulnerability Manager (GVM) 22.4 Installer
# Author: Fredrik Hilmersson <fredrik@libellux.com>
# Credits: Scott Shinn <scott@atomicorp.com>
#
# Description: GVM Installer
# Website: https://libellux.com/openvas/
# Support: https://ko-fi.com/libellux
#

# ERROR:  could not load library "/usr/lib/postgresql/14/lib/libpg-gvm.so": libgvm_base.so.22: cannot open shared object file: No such file or directory
# md manage:WARNING:2024-02-06 22h25.15 utc:65149: sql_exec_internal: PQexec failed: ERROR:  relation "public.meta" does not exist

set -uo pipefail

export DEBIAN_FRONTEND=noninteractive

if [[ $UID != 0 ]]; then
    echo "Please run this installer with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

installer_version="v1.0.0-dev"
last_updated="2024-02-06"
gvm_version="22.4"

SUCC="\033[0;32m"
ERR="\033[0;31m"
WARN="\033[0;33m"
ACK="\033[0;36m"
LINK="\033[0;34m"
LBX="\033[0;35m"
NC="\033[0m"

# Function to detect Linux distribution and version
detect_distro_version () {
    os=$(uname)
    if [ "$os" == "Linux" ]; then
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            distro=$ID
            version=$VERSION_ID
        elif [ -f /etc/lsb-release ]; then
            source /etc/lsb-release
            distro=$DISTRIB_ID
            version=$DISTRIB_RELEASE
        else
            echo "Unable to detect distribution and version."
            exit 1
        fi
    else
        echo "This script is intended for Linux systems only."
        exit 1
    fi
}

detect_distro_version

curl_download () {
    local url="$1"
    local output="$2"
    if curl -f -L -o "$output" "$url"; then
        echo "Downloaded $url to $output"
    else
        echo "Failed to download $url"
        exit 1
    fi
}

echo
echo -e ' __________'
echo -e '< Welcome! >'
echo -e ' ----------'
echo -e '      \'
echo -e '       \  >o)'
echo -e '          /\\'
echo -e '         _\_V'
echo
echo
echo -e "       =[ ${WARN}Libellux: Up & Running [GVM Installer $installer_version]${NC}"
echo -e "+ -- --=[ Description: Greenbone Vulnerability Manager ($gvm_version) installer"
echo -e "+ -- --=[ Usage: ${SUCC}sudo ./gvm-installer.sh --LISTEN=192.168.0.1 --SSL=true${NC}"
echo -e "+ -- --=[ Default IP listen 127.0.0.1 and SSL set to false"
echo -e "       =[ Last updated ${ACK}$((($(date +%s)-$(date +%s --date $last_updated))/(3600*24))) days ago${NC} ($last_updated)"
echo
echo -e "${WARN}Disclaimer:${NC} It is understood that this installer, and any configurations"
echo -e "may contain errors and are provided for education purposes only."
echo -e "The installer, and any configurations are provided "as is" without warranty"
echo -e "of any kind, whether express, implied, statutory, or otherwise."
echo -e "            For information about on how-to build GVM from source visit:"
echo -e "                ${LINK}https://libellux.com/openvas/${NC}"
echo

while true; do
read -p "Do you want to proceed? (y/n) " yn
case $yn in 
	[yY] ) echo ok, we will proceed;
		break;;
	[nN] ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac
done

if ! id -u "gvm" >/dev/null 2>&1; then
    useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm
else
    echo "User already exists"
fi

if ! id -nG "$USER" | grep -qw "gvm"; then
    usermod -aG gvm $USER 
else
    echo "$USER already belongs to group gvm"
fi

apt-get update --assume-yes
NEEDRESTART_MODE=a apt-get install --no-install-recommends --assume-yes \
build-essential \
curl \
cmake \
pkg-config \
python3 \
python3-pip \
gnupg

NEEDRESTART_MODE=a apt-get install --assume-yes \
gcc-mingw-w64 \
libgnutls28-dev \
libxml2-dev \
libssh-gcrypt-dev \
libunistring-dev \
libldap2-dev \
libgcrypt20-dev \
libpcap-dev \
libglib2.0-dev \
glib-2.0 \
libgpgme-dev \
libradcli-dev \
libjson-glib-dev \
libksba-dev \
libical-dev \
libpq-dev \
libsnmp-dev \
libpopt-dev \
libnet1-dev \
gnutls-bin \
libmicrohttpd-dev \
redis-server \
libhiredis-dev \
openssh-client \
xsltproc \
nmap \
bison \
postgresql \
postgresql-contrib \
postgresql-server-dev-14 \
smbclient \
fakeroot \
sshpass \
wget \
heimdal-dev \
dpkg \
rsync \
zip \
rpm \
nsis \
socat \
libbsd-dev \
snmp \
uuid-dev \
curl \
gpgsm \
python3-paramiko \
python3-lxml \
python3-defusedxml \
python3-psutil \
python3-impacket \
python3-setuptools \
python3-packaging \
python3-paho-mqtt \
python3-wrapt \
python3-cffi \
python3-redis \
python3-gnupg \
xmlstarlet \
texlive-fonts-recommended \
texlive-latex-extra \
perl-base \
xml-twig-tools \
libpaho-mqtt-dev \
mosquitto \
xmltoman \
doxygen \
graphviz

export INSTALL_PREFIX=/usr/local
export PATH=$PATH:$INSTALL_PREFIX/sbin
export SOURCE_DIR=$HOME/source
export BUILD_DIR=$HOME/build
export INSTALL_DIR=$HOME/install

mkdir -p $SOURCE_DIR
mkdir -p $BUILD_DIR
mkdir -p $INSTALL_DIR

export GVM_LIBS_VERSION=22.8.0
export GVMD_VERSION=23.2.0
export PG_GVM_VERSION=22.6.4
export GSA_VERSION=23.0.0
export GSAD_VERSION=22.9.0
export OPENVAS_SMB_VERSION=22.5.3
export OPENVAS_SCANNER_VERSION=22.7.9
export OSPD_OPENVAS_VERSION=22.6.2
export NOTUS_VERSION=22.6.2

export NODE_VERSION=node_16.x

curl_download https://www.greenbone.net/GBCommunitySigningKey.asc /tmp/GBCommunitySigningKey.asc
gpg --import /tmp/GBCommunitySigningKey.asc
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust

# gvm-libs download
curl_download https://github.com/greenbone/gvm-libs/archive/refs/tags/v$GVM_LIBS_VERSION.tar.gz $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz
curl_download https://github.com/greenbone/gvm-libs/releases/download/v$GVM_LIBS_VERSION/gvm-libs-v$GVM_LIBS_VERSION.tar.gz.asc $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# gvm-libs build
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz
mkdir -p $BUILD_DIR/gvm-libs
cd $BUILD_DIR/gvm-libs
cmake $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var
make -j$(nproc)
mkdir -p $INSTALL_DIR/gvm-libs
make DESTDIR=$INSTALL_DIR/gvm-libs install
cp -rv $INSTALL_DIR/gvm-libs/* /

# gvmd download
curl_download https://github.com/greenbone/gvmd/archive/refs/tags/v$GVMD_VERSION.tar.gz $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz
curl_download https://github.com/greenbone/gvmd/releases/download/v$GVMD_VERSION/gvmd-$GVMD_VERSION.tar.gz.asc $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz.asc $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# gvmd build
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz
mkdir -p $BUILD_DIR/gvmd
cd $BUILD_DIR/gvmd
cmake $SOURCE_DIR/gvmd-$GVMD_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DLOCALSTATEDIR=/var \
    -DSYSCONFDIR=/etc \
    -DGVM_DATA_DIR=/var \
    -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
    -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
    -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
    -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql \
    -DLOGROTATE_DIR=/etc/logrotate.d
make -j$(nproc)
mkdir -p $INSTALL_DIR/gvmd
make DESTDIR=$INSTALL_DIR/gvmd install
cp -rv $INSTALL_DIR/gvmd/* /

# pg-gvm download
curl_download https://github.com/greenbone/pg-gvm/archive/refs/tags/v$PG_GVM_VERSION.tar.gz $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz
curl_download https://github.com/greenbone/pg-gvm/releases/download/v$PG_GVM_VERSION/pg-gvm-$PG_GVM_VERSION.tar.gz.asc $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz.asc $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# pg-gvm build
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz
mkdir -p $BUILD_DIR/pg-gvm
cd $BUILD_DIR/pg-gvm
cmake $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql
make -j$(nproc)
mkdir -p $INSTALL_DIR/pg-gvm
make DESTDIR=$INSTALL_DIR/pg-gvm install
cp -rv $INSTALL_DIR/pg-gvm/* /

# gsa install
curl_download https://github.com/greenbone/gsa/releases/download/v$GSA_VERSION/gsa-dist-$GSA_VERSION.tar.gz $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz
curl_download https://github.com/greenbone/gsa/releases/download/v$GSA_VERSION/gsa-dist-$GSA_VERSION.tar.gz.asc $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz.asc $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

mkdir -p $SOURCE_DIR/gsa-$GSA_VERSION
tar -C $SOURCE_DIR/gsa-$GSA_VERSION -xvzf $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz
mkdir -p $INSTALL_PREFIX/share/gvm/gsad/web/
cp -rv $SOURCE_DIR/gsa-$GSA_VERSION/* $INSTALL_PREFIX/share/gvm/gsad/web/

# gsad download
curl_download https://github.com/greenbone/gsad/archive/refs/tags/v$GSAD_VERSION.tar.gz $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz
curl_download https://github.com/greenbone/gsad/releases/download/v$GSAD_VERSION/gsad-$GSAD_VERSION.tar.gz.asc $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz.asc $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# gsad build
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz
mkdir -p $BUILD_DIR/gsad
cd $BUILD_DIR/gsad
cmake $SOURCE_DIR/gsad-$GSAD_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DGVMD_RUN_DIR=/run/gvmd \
    -DGSAD_RUN_DIR=/run/gsad \
    -DLOGROTATE_DIR=/etc/logrotate.d
make -j$(nproc)
mkdir -p $INSTALL_DIR/gsad
make DESTDIR=$INSTALL_DIR/gsad install
cp -rv $INSTALL_DIR/gsad/* /

# openvas-smb download
curl_download https://github.com/greenbone/openvas-smb/archive/refs/tags/v$OPENVAS_SMB_VERSION.tar.gz $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz
curl_download https://github.com/greenbone/openvas-smb/releases/download/v$OPENVAS_SMB_VERSION/openvas-smb-v$OPENVAS_SMB_VERSION.tar.gz.asc $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz.asc $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# openvas-smb build
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz
mkdir -p $BUILD_DIR/openvas-smb
cd $BUILD_DIR/openvas-smb
cmake $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
mkdir -p $INSTALL_DIR/openvas-smb
make DESTDIR=$INSTALL_DIR/openvas-smb install
cp -rv $INSTALL_DIR/openvas-smb/* /

# openvas-scanner download
curl_download https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_SCANNER_VERSION.tar.gz $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz
curl_download https://github.com/greenbone/openvas-scanner/releases/download/v$OPENVAS_SCANNER_VERSION/openvas-scanner-v$OPENVAS_SCANNER_VERSION.tar.gz.asc $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz.asc $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# openvas-scanner build
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz
mkdir -p $BUILD_DIR/openvas-scanner
cd $BUILD_DIR/openvas-scanner
cmake $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DINSTALL_OLD_SYNC_SCRIPT=OFF \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
    -DOPENVAS_RUN_DIR=/run/ospd
make -j$(nproc)
mkdir -p $INSTALL_DIR/openvas-scanner
make DESTDIR=$INSTALL_DIR/openvas-scanner install
cp -rv $INSTALL_DIR/openvas-scanner/* /

# ospd-openvas download
curl_download https://github.com/greenbone/ospd-openvas/archive/refs/tags/v$OSPD_OPENVAS_VERSION.tar.gz $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz
curl_download https://github.com/greenbone/ospd-openvas/releases/download/v$OSPD_OPENVAS_VERSION/ospd-openvas-v$OSPD_OPENVAS_VERSION.tar.gz.asc $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz.asc $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# ospd-openvas install
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz
cd $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION
mkdir -p $INSTALL_DIR/ospd-openvas
python3 -m pip install --root=$INSTALL_DIR/ospd-openvas --no-warn-script-location .
cp -rv $INSTALL_DIR/ospd-openvas/* /

# notus-scanner download
curl_download https://github.com/greenbone/notus-scanner/archive/refs/tags/v$NOTUS_VERSION.tar.gz $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz
curl_download https://github.com/greenbone/notus-scanner/releases/download/v$NOTUS_VERSION/notus-scanner-v$NOTUS_VERSION.tar.gz.asc $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz.asc $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz

if [ $? -ne 0 ]; then
    echo "Invalid signature"
    exit 1
fi

# notus-scanner install
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz
cd $SOURCE_DIR/notus-scanner-$NOTUS_VERSION
mkdir -p $INSTALL_DIR/notus-scanner
python3 -m pip install --root=$INSTALL_DIR/notus-scanner --no-warn-script-location .
cp -rv $INSTALL_DIR/notus-scanner/* /

# gvm-tools install
mkdir -p $INSTALL_DIR/gvm-tools
python3 -m pip install --root=$INSTALL_DIR/gvm-tools --no-warn-script-location gvm-tools
cp -rv $INSTALL_DIR/gvm-tools/* /

# mosquitto
systemctl start mosquitto.service
systemctl enable mosquitto.service
echo -e "mqtt_server_uri = localhost:1883\ntable_driven_lsc = yes" | tee -a /etc/openvas/openvas.conf

# redis
cp $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION/config/redis-openvas.conf /etc/redis/
chown redis:redis /etc/redis/redis-openvas.conf
echo "db_address = /run/redis-openvas/redis.sock" | tee -a /etc/openvas/openvas.conf
systemctl start redis-server@openvas.service
systemctl enable redis-server@openvas.service
usermod -aG redis gvm

mkdir -p /var/lib/notus
mkdir -p /run/gvmd
chown -R gvm:gvm /var/lib/gvm
chown -R gvm:gvm /var/lib/openvas
chown -R gvm:gvm /var/lib/notus
chown -R gvm:gvm /var/log/gvm
chown -R gvm:gvm /run/gvmd
chmod -R g+srw /var/lib/gvm
chmod -R g+srw /var/lib/openvas
chmod -R g+srw /var/log/gvm
chown gvm:gvm /usr/local/sbin/gvmd
chmod 6750 /usr/local/sbin/gvmd

curl_download https://www.greenbone.net/GBCommunitySigningKey.asc /tmp/GBCommunitySigningKey.asc
export GNUPGHOME=/tmp/openvas-gnupg
mkdir -p $GNUPGHOME
gpg --import /tmp/GBCommunitySigningKey.asc
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust

export OPENVAS_GNUPG_HOME=/etc/openvas/gnupg
mkdir -p $OPENVAS_GNUPG_HOME
cp -r /tmp/openvas-gnupg/* $OPENVAS_GNUPG_HOME/
chown -R gvm:gvm $OPENVAS_GNUPG_HOME

if ! cat /etc/sudoers | grep -xqFe "%gvm ALL = NOPASSWD: /usr/local/sbin/openvas"; then
    cp /etc/sudoers /tmp/sudoers.bak
    echo "%gvm ALL = NOPASSWD: /usr/local/sbin/openvas" >> /tmp/sudoers.bak
    visudo -cf /tmp/sudoers.bak
    if [ $? -eq 0 ]; then
        cp /tmp/sudoers.bak /etc/sudoers
    else
        echo "Could not modify /etc/sudoers file. Please do this manually."
        exit 1
    fi
else
  echo "gvm group already allowed to run the openvas-scanner application"
fi

systemctl start postgresql@14-main.service

su - postgres -c "createuser -DRS gvm"
su - postgres -c "createdb -O gvm gvmd"
su - postgres -c "psql gvmd -q --command='create role dba with superuser noinherit;'"
su - postgres -c "psql gvmd -q --command='grant dba to gvm;'"
su - postgres -c "psql gvmd -q --command='create extension \"uuid-ossp\";'"
su - postgres -c "psql gvmd -q --command='create extension \"pgcrypto\";'"
su - postgres -c "psql gvmd -q --command='create extension \"pg-gvm\";'"
    
systemctl restart postgresql@14-main.service

ldconfig

if ! $(/usr/local/sbin/gvmd --get-users | grep -q ^admin) ; then
	echo 
	echo "Set the GSAD admin users password."
	echo "The admin user is used to configure accounts,"
	echo "Update NVT's manually, and manage roles."
	echo 
	USERNAME=admin
	if [[ -t 0 ]]; then
		stty -echo
	fi
	PASSCONFIRMED=0
	while [ $PASSCONFIRMED -lt 1 ]; do
		read -s -p "Enter Administrator Password: " PASSWORD
		echo
		read -s -p "Verify Administrator Password: " PASSWORD2
		echo
		if [ "$PASSWORD" == "$PASSWORD2" ]; then
			if [ "$PASSWORD" == "" ]; then
				echo "Empty password not allowed."
				PASSCONFIRMED=0
			else
				PASSCONFIRMED=1
			fi
			echo
		else
			echo "Passwords do not match"
			echo
		fi
	done
	stty echo

	/usr/local/sbin/gvmd  --create-user=${USERNAME}>/dev/null 2>&1
	/usr/local/sbin/gvmd  --user=${USERNAME} --new-password='${PASSWORD}'
	FEED_OWNER=$(/usr/local/sbin/gvmd --get-users --verbose | awk '/^admin / {print $2}')
	if [[ $FEED_OWNER == "" ]]; then
		echo "Error: Feed owner could not be found"
		exit 1
	fi
	/usr/local/sbin/gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $FEED_OWNER
fi

# greenbone-feed-sync install
mkdir -p $INSTALL_DIR/greenbone-feed-sync
python3 -m pip install --root=$INSTALL_DIR/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync
cp -rv $INSTALL_DIR/greenbone-feed-sync/* /

# greenbone-feed-sync
/usr/local/bin/greenbone-feed-sync

## ospd-openvas systemd
cat << EOF > $BUILD_DIR/ospd-openvas.service
[Unit]
Description=OSPd Wrapper for the OpenVAS Scanner (ospd-openvas)
Documentation=man:ospd-openvas(8) man:openvas(8)
After=network.target networking.service redis-server@openvas.service mosquitto.service
Wants=redis-server@openvas.service mosquitto.service notus-scanner.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=ospd
RuntimeDirectoryMode=2775
PIDFile=/run/ospd/ospd-openvas.pid
ExecStart=/usr/local/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0o770 --mqtt-broker-address localhost --mqtt-broker-port 1883 --notus-feed-dir /var/lib/notus/advisories
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

cp $BUILD_DIR/ospd-openvas.service /etc/systemd/system/

# notus-scanner systemd
cat << EOF > $BUILD_DIR/notus-scanner.service
[Unit]
Description=Notus Scanner
Documentation=https://github.com/greenbone/notus-scanner
After=mosquitto.service
Wants=mosquitto.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
RuntimeDirectory=notus-scanner
RuntimeDirectoryMode=2775
PIDFile=/run/notus-scanner/notus-scanner.pid
ExecStart=/usr/local/bin/notus-scanner --foreground --products-directory /var/lib/notus/products --log-file /var/log/gvm/notus-scanner.log
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

cp $BUILD_DIR/notus-scanner.service /etc/systemd/system/

## GVMD systemd
cat << EOF > $BUILD_DIR/gvmd.service
[Unit]
Description=Greenbone Vulnerability Manager daemon (gvmd)
After=network.target networking.service postgresql.service ospd-openvas.service
Wants=postgresql.service ospd-openvas.service
Documentation=man:gvmd(8)
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
PIDFile=/run/gvmd/gvmd.pid
RuntimeDirectory=gvmd
RuntimeDirectoryMode=2775
ExecStart=/usr/local/sbin/gvmd --foreground --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

cp $BUILD_DIR/gvmd.service /etc/systemd/system/

## GSAD systemd
cat << EOF > $BUILD_DIR/gsad.service
[Unit]
Description=Greenbone Security Assistant daemon (gsad)
Documentation=man:gsad(8) https://www.greenbone.net
After=network.target gvmd.service
Wants=gvmd.service

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=gsad
RuntimeDirectoryMode=2775
PIDFile=/run/gsad/gsad.pid
ExecStart=/usr/local/sbin/gsad --foreground --listen=127.0.0.1 --port=9392 --http-only
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
Alias=greenbone-security-assistant.service
EOF

cp $BUILD_DIR/gsad.service /etc/systemd/system/

## Reload the system daemon to enable the startup scripts
systemctl daemon-reload
systemctl start notus-scanner
systemctl start ospd-openvas
systemctl start gvmd
systemctl start gsad
systemctl enable notus-scanner
systemctl enable ospd-openvas
systemctl enable gvmd
systemctl enable gsad

# add if IP is set to different and/or if SSL is set to true to display correct login path
# add a happy penguin that says complete instead
echo
echo -e ' ___________'
echo -e '< Complete! >'
echo -e ' -----------'
echo -e '      \'
echo -e '       \  >o)'
echo -e '          /\\'
echo -e '         _\_V'
echo
echo -e "       =[ ${WARN}Libellux: Up & Running [GVM Installer $installer_version${NC}] ${SUCC}Complete!${NC}"
echo -e "+ -- --=[ Log in to GSAD at ${LINK}http://localhost:9392${NC}"
echo -e "       =[ Support me at: ${LINK}https://ko-fi.com/libellux${NC}"
echo
echo -e "${WARN}Disclaimer:${NC} It is understood that this installer, and any configurations may contain errors"
echo -e "            and are provided for education purposes only. The installer, and any configurations"
echo -e "            are provided "as is" without warranty of any kind, whether express, implied, statutory, or otherwise."
echo -e "            For information about on how-to build GVM from source visit:"
echo -e "                 ${LINK}https://libellux.com/openvas/${NC}"
echo