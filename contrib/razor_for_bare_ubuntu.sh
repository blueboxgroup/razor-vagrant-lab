#!/usr/bin/env bash

set -e

default_precise_iso_url="http://ubuntu-cd.mirror.iweb.ca/precise/ubuntu-12.04.1-server-amd64.iso"
default_policy_tag="virtualbox_vm"
default_role_tag='role__web_server'

iso_cache_dir=/opt/razor/image/cache

variant="$(echo $(basename $0) | awk -F'_' '{print $3}')"

usage() {
  printf "
Usage

  $(basename $0) [options] [action]

Options

  --iso-url|-u <url>      - The URL to download Ubuntu ISO, defaults to
                            '$default_precise_iso_url'
  --policy-tag|-t <tags>  - Razor policy tags, defaults to '$default_policy_tag'
                            and to '$default_role_tag' for chef setups

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

razor_model_uuid() {
  razor -w model \
    | NAME="$1" ruby -rjson -e '
      j = JSON.parse(STDIN.read);
      puts j["response"].
        select { |m| m["@label"] == ENV["NAME"] }.
        first["@uuid"]
    '
}

razor_tag_uuid() {
  razor -w tag \
    | NAME="$1" ruby -rjson -e '
      j = JSON.parse(STDIN.read);
      puts j["response"].
        select { |b| b["@name"] == ENV["NAME"] }.
        first["@uuid"]
    '
}

razor_broker_uuid() {
  razor -w broker \
    | NAME="$1" ruby -rjson -e '
      j = JSON.parse(STDIN.read);
      puts j["response"].
        select { |b| b["@name"] == ENV["NAME"] }.
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

add_bare_tag() {
  log "[Razor] adding no tags"
}

add_chef_tag() {
  log "[Razor] tag add $policy_tag"
  razor tag add \
    --name "$policy_tag" \
    --tag "$policy_tag"

  razor tag $(razor_tag_uuid "$policy_tag") matcher add \
    --key productname \
    --compare equal \
    --value VirtualBox
}

add_bare_broker() {
  log "[Razor] adding no brokers"
}

add_chef_broker() {
  log "[Razor] broker add chef"
  razor broker add \
    --plugin chef \
    --name lab_chef \
    --description "Sample Chef broker"
}

add_bare_policy() {
  log "[Razor] policy add ubuntu_bare"
  razor policy add \
    --template linux_deploy \
    --model-uuid $(razor_model_uuid precise64) \
    --tags "$policy_tag" \
    --enabled true \
    --label ubuntu_bare
}

add_chef_policy() {
  log "[Razor] policy add ubuntu_bare"
  razor policy add \
    --template linux_deploy \
    --model-uuid $(razor_model_uuid precise64) \
    --tags "$policy_tag" \
    --enabled true \
    --label ubuntu_chef \
    --broker-uuid $(razor_broker_uuid lab_chef)
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

    --policy-tag|-t)
      policy_tag="$1" ; shift
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
if [ -z "$policy_tag" ] ; then
  if [ "$variant" == "chef" ] ; then
    policy_tag="$default_role_tag"
  else
    policy_tag="$default_policy_tag"
  fi
fi

precise_iso="$iso_cache_dir/${precise_iso_url##http*/}"

install_curl
download_iso
add_image
add_model
add_${variant}_tag
add_${variant}_broker
add_${variant}_policy
finished
