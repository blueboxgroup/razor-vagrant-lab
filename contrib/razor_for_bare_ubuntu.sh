#!/usr/bin/env bash

set -e

default_precise_iso_url="http://releases.ubuntu.com/precise/ubuntu-12.04.2-server-amd64.iso"
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

banner()  { printf -- "-----> $*\n" ; }
log()     { printf -- "       $*\n" ; }
warn()    { printf -- ">>>>>> $*\n" ; }

trap 'warn "Bailing out"' SIGTERM

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
  banner "Installing curl for API calls"
  apt-get -y install curl
}

download_iso() {
  mkdir -p $iso_cache_dir

  if [ ! -f "$precise_iso" ] ; then
    banner "Downloading ISO from $precise_iso_url"
    curl -L $precise_iso_url -o $precise_iso
  else
    banner "ISO $precise_iso already downloaded, skipping"
  fi
}

add_image() {
  banner "[Razor] image add ubuntu-amd64/12.04"
  razor image add \
    --type os \
    --path $precise_iso \
    --name ubuntu-amd64 \
    --version 12.04
}

add_model() {
  printf -- "\n\n\n"
  banner "[Cheat Sheet] Answers to Model questions"
  log "1. 'node hostname prefix': web"
  log "2. 'local domain name':    razornet.local"
  log "3. 'root password':        test1234"
  printf -- "\n\n\n"

  banner "[Razor] model add precise64"
  razor model add \
    --template ubuntu_precise \
    --image-uuid $(razor_image_uuid ubuntu-amd64 12.04) \
    --label precise64
}

add_bare_tag() {
  banner "[Razor] adding no tags"
}

add_chef_tag() {
  banner "[Razor] tag add $policy_tag"
  razor tag add \
    --name "$policy_tag" \
    --tag "$policy_tag"

  razor tag $(razor_tag_uuid "$policy_tag") matcher add \
    --key productname \
    --compare equal \
    --value VirtualBox
}

add_puppet_tag() {
  banner "[Razor] adding no tags"
}

add_bare_broker() {
  banner "[Razor] adding no brokers"
}

add_chef_broker() {
  if [ ! -f "/vagrant/tmp/chef_server/chef-validator.pem" ] ; then
    warn "Could not find the chef-validator.pem key file."
    warn ""
    warn "  * If you are using your own Chef Server, please disregard."
    warn "  * If you want to use the provided Vagrant Chef Server, please"
    warn "    quit and run 'vagrant up chef' on your workstation.\n"
  fi

  printf -- "\n\n\n"
  banner "[Cheat Sheet] Answers to Chef Broker questions"
  log "1. 'the URL for the Chef server':  https://chef.razornet.local"
  log "2. 'the Chef version':             11.4.0"
  log "3. 'contents of validation.pem':"
  if [ -f "/vagrant/tmp/chef_server/chef-validator.pem" ] ; then
    cat "/vagrant/tmp/chef_server/chef-validator.pem"
  else
    printf -- 'UNKNOWN??\n'
  fi
  log "4. 'the validation client name':   chef-validator"
  log "5. 'the Chef environment':         _default"
  log "6. 'the Omnibus installer URL':    http://opscode.com/chef/install.sh"
  log "7. 'path to chef-client binary':   chef-client"
  log "8. 'optional run_list':            <SKIP>"
  printf -- "\n\n\n"

  banner "[Razor] broker add chef"
  razor broker add \
    --plugin chef \
    --name lab_chef \
    --description "Sample Chef broker"
}

add_puppet_broker() {
  banner "[Razor] broker add puppet"
  razor broker add \
    --plugin puppet \
    --name lab_puppet \
    --description "Sample Puppet broker"
}

add_bare_policy() {
  banner "[Razor] policy add ubuntu_bare"
  razor policy add \
    --template linux_deploy \
    --model-uuid $(razor_model_uuid precise64) \
    --tags "$policy_tag" \
    --enabled true \
    --label ubuntu_bare
}

add_chef_policy() {
  banner "[Razor] policy add ubuntu_bare"
  razor policy add \
    --template linux_deploy \
    --model-uuid $(razor_model_uuid precise64) \
    --tags "$policy_tag" \
    --enabled true \
    --label ubuntu_chef \
    --broker-uuid $(razor_broker_uuid lab_chef)
}

add_puppet_policy() {
  banner "[Razor] policy add ubuntu_bare"
  razor policy add \
    --template linux_deploy \
    --model-uuid $(razor_model_uuid precise64) \
    --tags "$policy_tag" \
    --enabled true \
    --label ubuntu_puppet \
    --broker-uuid $(razor_broker_uuid lab_puppet)
}

finished() {
  banner "Finished, client nodes should pick up policy shortly"
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
