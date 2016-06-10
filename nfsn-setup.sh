#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

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
printf '
 + Done.

   Now add nfsn-cron.sh to your scheduled tasks so that the certificates
   will be renewed automatically.  To do that, go to

	https://members.nearlyfreespeech.net/%s/sites/%s/cron

   and use the following settings:

	Tag:                  lets-nfsn
	URL or Shell Command: %q %q
	User:                 me
	Hour:                 %d
	Day of Week:          Every
	Date:                 *

   The certificates will be renewed only when needed so it’s safe to schedule
   the task to run daily.
' \
	"${user_site%_*}" "$NFSN_SITE_NAME" \
	"$BASH" "$(realpath nfsn-cron.sh)" \
	"$(( $RANDOM % 24 ))"
