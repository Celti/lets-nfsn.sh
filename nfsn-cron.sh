#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

cd "$(dirname "$0")"

echo " + Updating lets-nfsn.sh..."
git pull

echo " + Updating dehydrated..."
git submodule update --remote
cd dehydrated

echo " + Checking certificate expiration date..."
if find certs -name cert.pem -type l \
	-exec openssl x509 -checkend 2592000 -in {} \; |
		grep -qF "Certificate will expire"; then
	echo " + Certificate will expire in 30 days or less! SSH into this site and"
	echo "   run the following commands to renew your certificates:"
	printf '	%q --cron\n' "$(realpath dehydrated)"
	echo " + This error message will repeat daily."
	exit 1
else
	echo " + More than 30 days until any certificate expires. Exiting."
	exit 0
fi

echo " + Running letsencrypt.sh..."
./dehydrated --cron

echo " + Cleaning up old certificates..."
./dehydrated --cleanup
