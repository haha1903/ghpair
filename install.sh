#!/bin/sh

set -e

AZURE_COM_SUB="$1"
AZURE_CN_SUB="$2"

cd `dirname $0`

# Make tr work under OSX
export LC_ALL=C
GROUP_NAME="hai"
SERVER_LOCATION="southeastasia"
CLIENT_LOCATION="chinaeast2"
SSPORT=43456

# Generate passwords
GHPASS=`date | md5 | head -c8`
SSPASS=`date | md5 | head -c8`

# Generate ssh key
if [ ! -f $HOME/.ssh/id_rsa-gohop.pub ]; then
    ssh-keygen -f $HOME/.ssh/id_rsa-gohop -t rsa -N ''
fi
SSHKEY=`cat $HOME/.ssh/id_rsa-gohop.pub`

echo "Logging into azure.com..."
az cloud set -n AzureCloud
az account set -s "$AZURE_COM_SUB"
echo "Deploying Gohop server..."
az deployment sub create -l $SERVER_LOCATION -f server/main.bicep -p rgName="$GROUP_NAME" -p sshPublicKey="$SSHKEY" \
    -p ghPassword="$GHPASS"
GHSADDR=`az network public-ip show -n goserver-ip -g $GROUP_NAME | jq -r '.ipAddress'`
echo "Gohop server is running at $GHSADDR:40000-41000"

# Create gohop client
echo "Logging into azure.cn..."
az cloud set -n AzureChinaCloud
az account set -s "$AZURE_CN_SUB"
echo "Deploying Gohop client and shadowsocks server..."
az deployment sub create -l $CLIENT_LOCATION -f client/main.bicep -p rgName="$GROUP_NAME" -p sshPublicKey="$SSHKEY" \
    -p ghPassword="$GHPASS" -p ssPassword="$SSPASS" -p ssPort="$SSPORT" -p ghServer="$GHSADDR"
GHCADDR=`az network public-ip show -n goclient-ip -g $GROUP_NAME | jq -r '.ipAddress'`
echo "Shadowsocks server is running at $GHCADDR:$SSPORT"

echo "Using following config file for shadowsocks client:"
cat << EOF
{
    "server":"$GHCADDR",
    "server_port":$SSPORT,
    "local_address":"local_address_to_bind",
    "local_port": local_port_to_bind,
    "password":"$SSPASS",
    "timeout":600,
    "method":"aes-256-cfb"
}
EOF
SSURL=`echo "aes-256-cfb:$SSPASS@$GHCADDR:$SSPORT" | base64`

echo
echo
echo "For iOS devices, install Shadowrocket at https://itunes.apple.com/cn/app/shadowrocket/id932747118?mt=8"
echo " and scan this QR Code"
echo "https://api.qrserver.com/v1/create-qr-code/?data=ss://$SSURL"
