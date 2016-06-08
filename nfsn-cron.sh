#!/usr/bin/env bash
set -eu

cd $(dirname $0)

echo " + Updating lets-nfsn.sh..."
git pull

echo " + Updating letsencrypt.sh..."
git submodule update --remote
cd letsencrypt.sh

echo " + Updating domains.txt..."
nfsn -s list-aliases > domains.txt

echo " + Running letsencrypt.sh..."
./letsencrypt.sh --cron

echo " + Cleaning up old certificates..."
./letsencrypt.sh --cleanup
