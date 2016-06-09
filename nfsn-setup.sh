#!/usr/bin/env bash
set -eu

echo " + Cloning letsencrypt.sh git repository..."
git submodule init
git submodule update

echo " + Setting challenge directory..."
mkdir -p "${DOCUMENT_ROOT}/.well-known/acme-challenge"
echo "WELLKNOWN='${DOCUMENT_ROOT}/.well-known/acme-challenge'" > letsencrypt.sh/config

echo " + Installing hook script..."
chmod +x nfsn-hook.sh
echo "HOOK='$(realpath nfsn-hook.sh)'" >> letsencrypt.sh/config

echo " + Generating domains.txt..."
nfsn -s list-aliases > letsencrypt.sh/domains.txt

echo " + Performing initial run..."
letsencrypt.sh/letsencrypt.sh --cron

user_site=${MAIL##*/}
echo " + Done! Now add $(realpath nfsn-cron.sh) to your scheduled tasks!"
echo "   You can find them at https://members.nearlyfreespeech.net/${user_site%_*}/sites/${NFSN_SITE_NAME}/cron"
echo "   letsencrypt.sh will not try and renew the script unless it expires in less than 30 days."
echo "   I recommend running it daily, to ensure plenty of warning if the renewal fails."
