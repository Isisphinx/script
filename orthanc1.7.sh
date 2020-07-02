#!/bin/sh

apt update

DEBIAN_FRONTEND=noninteractive apt install -y build-essential unzip cmake mercurial uuid-dev libcurl4-openssl-dev liblua5.3-dev libgtest-dev libpng-dev libsqlite3-dev libssl-dev libjpeg-dev zlib1g-dev libdcmtk-dev libboost-all-dev libwrap0-dev libcharls-dev libjsoncpp-dev libpugixml-dev locales

mkdir /home/bin
cd /home/bin/

wget -O Orthanc-1.7.1.tar.gz https://www.orthanc-server.com/downloads/get.php?path=/orthanc/Orthanc-1.7.1.tar.gz
tar zxvf Orthanc-1.7.1.tar.gz
rm Orthanc-1.7.1.tar.gz
mkdir OrthancBuild
cd OrthancBuild
cmake /home/bin/Orthanc-1.7.1 -DALLOW_DOWNLOADS=ON -DUSE_GOOGLE_TEST_DEBIAN_PACKAGE=ON -DUSE_SYSTEM_CIVETWEB=OFF -DDCMTK_LIBRARIES=dcmjpls -DCMAKE_BUILD_TYPE=Release
make
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
rm -rf /home/bin/Orthanc-1.7.1

cd /home/bin/
wget -O OrthancPostgreSQL-3.2.tar.gz https://www.orthanc-server.com/downloads/get.php?path=/plugin-postgresql/OrthancPostgreSQL-3.2.tar.gz
tar zxvf OrthancPostgreSQL-3.2.tar.gz
rm OrthancPostgreSQL-3.2.tar.gz
mkdir PostgreSQLBuild
cd PostgreSQLBuild
cmake /home/bin/OrthancPostgreSQL-3.2/PostgreSQL -DSTATIC_BUILD=ON -DCMAKE_BUILD_TYPE=Release
make
rm -rf /home/bin/OrthancPostgreSQL-3.2

cd /home/bin/
wget -O OrthancTransfers-1.0.tar.gz https://www.orthanc-server.com/downloads/get.php?path=/plugin-transfers/OrthancTransfers-1.0.tar.gz
tar zxvf OrthancTransfers-1.0.tar.gz
rm OrthancTransfers-1.0.tar.gz
mkdir TransfersBuild
cd TransfersBuild
cmake /home/bin/OrthancTransfers-1.0 -DSTATIC_BUILD=ON -DCMAKE_BUILD_TYPE=Release
make
rm -rf /home/bin/OrthancTransfers-1.0

cd /home/bin/
wget -O OrthancWebViewer-2.6.tar.gz https://www.orthanc-server.com/downloads/get.php?path=/plugin-webviewer/OrthancWebViewer-2.6.tar.gz
tar zxvf OrthancWebViewer-2.6.tar.gz
rm OrthancWebViewer-2.6.tar.gz
mkdir OrthancWebViewerBuild
cd OrthancWebViewerBuild
cmake /home/bin/OrthancWebViewer-2.6 -DSTATIC_BUILD=ON -DCMAKE_BUILD_TYPE=Release
make
rm -rf /home/bin/OrthancWebViewer-2.6

cd /home/bin/
wget -O OrthancDicomWeb-1.2.tar.gz https://www.orthanc-server.com/downloads/get.php?path=/plugin-dicom-web/OrthancDicomWeb-1.2.tar.gz
tar zxvf OrthancDicomWeb-1.2.tar.gz
rm OrthancDicomWeb-1.2.tar.gz
mkdir DicomWebBuild
cd DicomWebBuild
cmake /home/bin/OrthancDicomWeb-1.2 -DSTATIC_BUILD=ON -DCMAKE_BUILD_TYPE=Release
make
rm -rf /home/bin/OrthancDicomWeb-1.2

apt install -y postgresql
sudo -u postgres createdb orthanc
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"

cat <<EOF > /home/bin/OrthancBuild/configuration.json
{
"HttpPort": 80
,"DicomPort" : 11112
,"RemoteAccessAllowed" : true
,"AuthenticationEnabled" : true
,"RegisteredUsers" : {
    "alice" : "alicePassword"
  }
,"StorageCompression" : true
,"PostgreSQL" : {
    "EnableIndex" : true
    ,"ConnectionUri" : "postgresql://postgres:postgres@localhost:5432/orthanc"
  }
  ,"Plugins" : [
    "/home/bin/PostgreSQLBuild/libOrthancPostgreSQLIndex.so"
    ,"/home/bin/OrthancWebViewerBuild/libOrthancWebViewer.so"
    ,"/home/bin/TransfersBuild/libOrthancTransfers.so"
    ,"/home/bin/DicomWebBuild/libOrthancDicomWeb.so"
  ]
}
EOF

cat <<EOF > /etc/systemd/system/orthanc.service
[Unit]
Description=Orthanc DICOM server
Documentation=man:Orthanc(1) http://www.orthanc-server.com/
After=syslog.target network.target
[Service]
Type=simple
ExecStart=/home/bin/OrthancBuild/Orthanc /home/bin/OrthancBuild/configuration.json
[Install]
WantedBy=multi-user.target
EOF

systemctl start orthanc.service
systemctl enable orthanc.service
