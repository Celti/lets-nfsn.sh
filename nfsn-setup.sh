#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

echo " + Cloning letsencrypt.sh git repository..."
git submodule init
git submodule update

echo " + Setting challenge directory..."
WELLKNOWN="${DOCUMENT_ROOT}/.well-known/acme-challenge"
echo "WELLKNOWN='${WELLKNOWN}'" > letsencrypt.sh/config
mkdir -p "${WELLKNOWN}"

echo " + Symlinking challenge directory into document root(s)..."
for site_root in $(nfsn list-aliases); do
   if [[ -d "${DOCUMENT_ROOT}/${site_root}/" ]]; then
      ln -s "${WELLKNOWN}" "${DOCUMENT_ROOT}/${site_root}/.well-known/acme-challenge"
   fi
done

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

   The certificates will be renewed only when needed so it’s safe to
   schedule the task to run daily.

 + ATTN: /usr/local/bin/nfsn currently does not support being run from
         cron. A solution is being discussed; until one is available,
         this task will simply check the expiration date and error if it
         is within 30 days of expiry.
' \
	"${user_site%_*}" "$NFSN_SITE_NAME" \
	"$BASH" "$(realpath nfsn-cron.sh)" \
	"$(( $RANDOM % 24 ))"
