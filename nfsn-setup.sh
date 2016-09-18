#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

readonly well_known='.well-known/acme-challenge/'
readonly hook_path=$(realpath nfsn-hook.sh)
declare single_cert='true'

echo " + Cloning dehydrated git repository..."
git submodule init
git submodule update --remote
cd dehydrated

# write_config $config_dir $wellknown
write_config() {
    mkdir -p -- "$1" "$2"
    printf '%s=%q\n' WELLKNOWN "$2" HOOK "$hook_path" >"$1/config"
}

echo " + Generating configuration..."
for site_root in $(nfsn list-aliases); do
   if [[ -d "${DOCUMENT_ROOT}${site_root}/" ]]; then
      write_config "certs/${site_root}" \
                   "${DOCUMENT_ROOT}${site_root}/${well_known}"
      unset single_cert
   fi
done

if [[ "${single_cert:+true}" ]]; then
   echo " + Generating fallback configuration..."
   write_config . "${DOCUMENT_ROOT}${well_known}"
fi

echo " + Generating domains.txt..."
nfsn ${single_cert:+-s} list-aliases > domains.txt

echo " + Performing initial run..."
./letsencrypt.sh --cron

user_site=${MAIL##*/}
printf '
 + Done.

   Now add nfsn-cron.sh to your scheduled tasks so that the certificates
   will be renewed automatically.  To do that, go to

	https://members.nearlyfreespeech.net/%s/sites/%s/cron

   and use the following settings:

	Tag:                  letsencrypt
	URL or Shell Command: %q
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
	"$(realpath ../nfsn-cron.sh)" \
	"$(( $RANDOM % 24 ))"
