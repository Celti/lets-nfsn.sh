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

echo " + Updating letsencrypt.sh..."
git submodule update --remote
cd letsencrypt.sh

echo " + /usr/local/bin/nfsn cannot run from cron."
echo "   If you are executing this from the shell, run:"
echo "	${PWD}/letsencrypt.sh --cron"
echo "   to update your certificates."
echo

echo " + Checking certificate expiration date..."
declare -a checks=( $(find certs -name cert.pem -type l -exec openssl x509 -checkend 2592000 -in {} \;) )
if contains "Certificate will expire" "${checks[@]}"; then
	echo " + Certificte will expire in 30 days or less! Renew soon!"
	exit 1
else
	echo " + More than 30 days until any certificate expires. Exiting."
	exit 0
fi

echo " + Updating domains.txt..."
nfsn -s list-aliases > domains.txt

echo " + Running letsencrypt.sh..."
./letsencrypt.sh --cron

echo " + Cleaning up old certificates..."
./letsencrypt.sh --cleanup
