#!/bin/sh

: '
3G4GProxy installation script by Techta

Created By Son Bui, Jul 2020
'

#FILE_NAME="/home/$USER/Downloads/ProxySetup"
#$FILE_NAME

SERVICE_NAME=Proxy_Service.service
PATH_TO_JAR=/opt/3g4gProxy/proxy.jar
PID_PATH_NAME=/tmp/Proxy_Service-pid

YELLOW='\033[1;33m'
RED='\033[0;31m'
SET='\033[0m'

ENABLE_MAC_AUTO=false

func() {
  echo -n "Enter new MAC address: "
  read MAC
}

#Auto gen
MAC_AUTO=$(dbus-uuidgen | cut -c1-12 | sed -e 's/../:&/2g' -e 's/^://' | tr [:lower:] [:upper:])
echo "MAC address generator is ${RED}$MAC_AUTO${SET}"

#read -p "Do you want change mac address? " -n 1 -r
#echo # (optional) move to a new line
#if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#  exit 1
#fi

while true; do
  read -p "Do you want to use MAC address $MAC_AUTO ?(Y/n)" yn
  case $yn in
  [Nn]*)
    ENABLE_MAC_AUTO=true
    break
    ;;
  [Yy]*)
    MAC=$MAC_AUTO
    break
    ;;
    #  *) echo "Please answer yes or no." ;;
  *)
    MAC=$MAC_AUTO
    break
    ;;
  esac
done

if $ENABLE_MAC_AUTO; then
  while true; do
    func

    case $MAC in

    [0-9a-fA-F-][0-9a-fA-F-]:[0-9a-fA-F-][0-9a-fA-F-]:[0-9a-fA-F-][0-9a-fA-F-]:[0-9a-fA-F-][0-9a-fA-F-]:[0-9a-fA-F-][0-9a-fA-F-]:[0-9a-fA-F-][0-9a-fA-F-])
      break
      ;;
    *)
      echo "Not Valid, Try again"
      ;;
    esac

    # if [[ $var1 == "yes" ]] || [[ $var1 == "no" ]]
    # then
    # printf "I'm glag you said %s\n" "$var1"
    # break
    # fi
  done
fi

echo "${RED}MAC save is $MAC ${SET}"

#read -p "Press ENTER key to Exit" ENTER
#exit 1
#Start install

echo "Backup key install"
sudo cp /opt/3g4gProxy/.license.dat /opt/3g4gProxyBk/.license.dat

echo "Start install"

echo "${YELLOW}Clear Files${SET}"
rm -rf /opt/3g4gProxy
rm -rf /opt/3g4gProxy/Setup.zip

echo "${YELLOW}Change directory to /home${SET}"
cd /opt

echo "${YELLOW}Downloading source files${SET}"
wget http://vidieukhien.xyz/iot/proxy/Setup.zip
mkdir -p /opt/3g4gProxy
apt-get install unzip
unzip Setup.zip -d /opt/3g4gProxy/ && rm -r Setup.zip

echo "${YELLOW}Updating System${SET}"
apt-get update

echo "${YELLOW}Updating System${SET}"
apt-get update

echo "${YELLOW}Installing JDK${SET}"
sudo apt-get install default-jdk

echo "${YELLOW}Installing iproute2${SET}"
apt-get install iproute2

echo "${YELLOW}Installing Network Manager${SET}"
apt-get install network-manager

echo "${YELLOW}Installing Modem Manager${SET}"
apt-get install modemmanager

echo "${YELLOW}Installing PPP${SET}"
apt-get install ppp

echo "${YELLOW}Installing libbcprov-java${SET}"
apt-get install libbcprov-java

echo "${YELLOW}Installing net-tools${SET}"
apt-get install -y net-tools

echo "${YELLOW}Change directory to /opt/3g4gProxy${SET}"
cd /opt/3g4gProxy

echo "${YELLOW}Copy running file ${SET}"
cp -a ./Setup/. ./

rm -rf ./Setup

echo "${YELLOW}Copy setup system file ${SET}"
cp -r ./system/. ./

#Setting ethernet mac
sed -i "s/#MAC/$MAC/" 99-mac-address.rules
mv -f ./99-mac-address.rules /etc/udev/rules.d
chmod +x /etc/udev/rules.d/99-mac-address.rules

#Enable gsm manager
mv -f ./10-globally-managed-devices.conf /etc/NetworkManager/conf.d

#Set Wifi mac
mv -f ./30-mac-randomization.conf /etc/NetworkManager/conf.d

#Setting Hostname
mv -f ./hostname /etc
mv -f ./hosts /etc

#Setting dns
mv -f ./NetworkManager.conf /etc/NetworkManager
mv -f ./resolv.conf /etc

sudo service network-manager restart

#Setting Driver Usb

echo "${YELLOW}Installing usb-modeswitch${SET}"
apt-get install usb-modeswitch

sudo tar xf /usr/share/usb_modeswitch/configPack.tar.gz 12d1\:14fe -C /usr/share/usb_modeswitch/
mv -f ./40-usb_modeswitch.rules /lib/udev/rules.d
sudo service udev restart

# Dung sudo nen luon la root, khong can chay doan ma sau
#echo "${YELLOW}Disable sudo password for $USER ${SET}"
#wget http://vidieukhien.xyz/iot/proxy/dis_sudo_pass.txt -O $USER
#
#sed -i "s/#NAME/$USER/" $USER
#
#echo "${YELLOW}Moving ${RED}$USER${SET} to ${RED}/etc/sudoers.d/$USER ${SET}"
#mv $USER /etc/sudoers.d/$USER

echo "${YELLOW}Setup running as service${SET}"

echo "Check $SERVICE_NAME is running?"
if [ ! -f $PID_PATH_NAME ]; then
  echo "$SERVICE_NAME  not started ..."
else
  echo "$SERVICE_NAME is already running ..."
  echo "${YELLOW}Stop Service${SET}"
  systemctl stop $SERVICE_NAME

fi

echo "${YELLOW}Copying service default script${SET}"
#IPV6 Routing
sudo cp remove-route /etc/network/if-down.d/99-remove-route
sudo chmod +x /etc/network/if-down.d/99-remove-route
rm remove-route
sudo cp Service_Route_Ipv6.sh /opt/3g4gProxy/Service_Route_Ipv6.sh
sudo chmod a+rwx /opt/3g4gProxy/Service_Route_Ipv6.sh
sudo cp Ipv6_Route_Service.service /etc/systemd/system/Ipv6_Route_Service.service
sudo systemctl daemon-reload
sudo systemctl enable Ipv6_Route_Service.service
sudo systemctl start Ipv6_Route_Service.service
rm Service_Route_Ipv6.sh
rm Ipv6_Route_Service.service

#cp -r ./service/Service_Proxy.sh /usr/local/bin
mv ./service/Service_Proxy.sh /usr/local/bin
mv ./service/Service_Proxy_Update.sh /usr/local/bin
mv ./service/Service_Proxy_Shutdown.sh /usr/local/bin
mv ./service/Service_Proxy_Restart.sh /usr/local/bin

chmod +x /usr/local/bin/Service_Proxy.sh
chmod +x /usr/local/bin/Service_Proxy_Update.sh
chmod +x /usr/local/bin/Service_Proxy_Shutdown.sh
chmod +x /usr/local/bin/Service_Proxy_Restart.sh

#cp -r ./service/Proxy_Service.service /etc/systemd/system/
mv ./service/Proxy_Service.service /etc/systemd/system/
mv ./service/Proxy_Update_Service.service /etc/systemd/system/
mv ./service/Proxy_Shutdown_Service.service /etc/systemd/system/
mv ./service/Proxy_Restart_Service.service /etc/systemd/system/

echo "${YELLOW}Restore license key${SET}"
sudo cp /opt/3g4gProxyBk/.license.dat /opt/3g4gProxy/.license.dat
rm -rf /opt/3g4gProxyBk

echo "${YELLOW}Add To Service${SET}"
systemctl daemon-reload
echo "${YELLOW}Start Service${SET}"
systemctl start $SERVICE_NAME
echo "${YELLOW}Execute auto start service on next boot${SET}"
systemctl enable $SERVICE_NAME

echo "DONE"
#read -p "Press ENTER key to reboot" ENTER
reboot
