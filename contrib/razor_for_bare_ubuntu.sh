#!/usr/bin/env bash

set -e

default_precise_iso_url="http://ubuntu-cd.mirror.iweb.ca/precise/ubuntu-12.04.1-server-amd64.iso"
default_policy_tags="virtualbox_vm"
default_razor_uri="http://172.16.33.11:8026"

iso_cache_dir=/opt/razor/image/cache

usage() {
  printf "
Usage

  $(basename $0) [options] [action]

Options

  --iso-url|-u <url>      - The URL to download Ubuntu ISO, defaults to
                            '$default_precise_iso_url'
  --policy-tags|-t <tags> - Razor policy tags, defaults to 'virtualbox_vm'
  --razor-uri             - URI to local Razor API server, defaults to
                            '$default_razor_uri'

Action

  help - Display CLI help (this output)

"
}

log() { printf -- "-----> $*\n" ; return $? ; }

# OMGWTFBBQ, this should **not** be required
razor_image_uuid() {
  razor image | NAME="$1" VERSION="$2" ruby -e '
    puts STDIN.
      readlines.
      join.
      split("\n\n").
      collect{ |x| Hash[*(x.split(/\n|=>/) - ["Images"]).
      collect{|y| y.strip!}] }.
      select { |i| i["OS Name"] == ENV["NAME"] && i["OS Version"] == ENV["VERSION"] }.
      first["UUID"]
  '
}

# OMGWTFBBQ, this should **not** be required
razor_model_uuid() {
  curl -s "$razor_uri/razor/api/model" \
    | NAME="$1" ruby -rjson -e '
      j = JSON.parse(STDIN.read);
      puts j["response"].
        select { |m| m["@label"] == ENV["NAME"] }.
        first["@uuid"]
    '
}

install_curl() {
  log "Installing curl for API calls"
  apt-get -y install curl
}

download_iso() {
  mkdir -p $iso_cache_dir

  if [ ! -f "$precise_iso" ] ; then
    log "Downloading ISO from $precise_iso_url"
    curl -L $precise_iso_url -o $precise_iso
  else
    log "ISO $precise_iso already downloaded, skipping"
  fi
}

add_image() {
  log "[Razor] image add ubuntu-amd64/12.04"
  razor image add \
    --type os \
    --path $precise_iso \
    --name ubuntu-amd64 \
    --version 12.04
}

add_model() {
  log "[Razor] model add precise64"
  razor model add \
    --template ubuntu_precise \
    --image-uuid $(razor_image_uuid ubuntu-amd64 12.04) \
    --label precise64
}

add_policy() {
  log "[Razor] policy add ubuntu_bare"
  razor policy add \
    --template linux_deploy \
    --model-uuid $(razor_model_uuid precise64) \
    --tags "$policy_tags" \
    --enabled true \
    --label ubuntu_bare
}

finished() {
  log "Finished, client nodes should pick up policy shortly"
}

# Parse CLI arguments
while [[ $# -gt 0 ]] ; do
  token="$1" ; shift
  case "$token" in

    --iso-url|-u)
      precise_iso_url="$1" ; shift
      ;;

    --policy-tags|-t)
      policy_tags="$1" ; shift
      ;;

    --razor-uri)
      razor_uri="$1" ; shift
      ;;

    help|usage)
      usage
      exit 0
      ;;

    *)
      usage
      exit 1
      ;;

  esac
done

if [ -z "$precise_iso_url" ] ; then
  precise_iso_url="$default_precise_iso_url"
fi
if [ -z "$policy_tags" ] ; then
  policy_tags="$default_policy_tags"
fi
if [ -z "$razor_uri" ] ; then
  razor_uri="$default_razor_uri"
fi

precise_iso="$iso_cache_dir/${precise_iso_url##http*/}"

install_curl
download_iso
add_image
add_model
add_policy
finished
