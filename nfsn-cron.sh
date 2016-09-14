#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

contains() {
	local item; local needle="$1"
	shift && local -a haystack=("$@")
	for item in "${haystack[@]}"; do
		[[ $item = $needle ]] && return 0
	done
	return 1
}

cd "$(dirname "$0")"

echo " + Updating lets-nfsn.sh..."
git pull

echo " + Updating dehydrated..."
git submodule update --remote
cd dehydrated

echo " + Checking certificate expiration date..."
declare -a checks=( $(find certs -name cert.pem -type l -exec openssl x509 -checkend 2592000 -in {} \;) )
if contains "Certificate will expire" "${checks[@]}"; then
	echo " + Certificte will expire in 30 days or less! SSH into this site and"
	echo "   run the following commands to renew your certificates:"
	echo "	cd ~/lets-nfsn.sh/dehydrated/"
	echo "	./dehydrated --cron"
	echo " + This error message will repeat daily."
	exit 1
else
	echo " + More than 30 days until any certificate expires. Exiting."
	exit 0
fi

echo " + Running dehydrated..."
./dehydrated --cron

echo " + Cleaning up old certificates..."
./dehydrated --cleanup
