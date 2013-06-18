# Razor Vagrant Lab

## Initial Setup

Download and install the following on your workstation:

1. [VirtualBox][vb_site] (currently tested on version 4.2.4 on Mac)
2. [VirtualBox Oracle VM VirtualBox Extension Pack][vb_site] (needed for
   PXE booting support)
3. [Vagrant][vagrant_site] (package install, version 1.1.0 or higher)
4. [vagrant-berkshelf plugin][vagrant_berkshelf] (needed to resolve and use cookbooks)
5. [vagrant-omnibus plugin][vagrant_omnibus] (needed to install Chef on the Vagrant VMs)

**Note:** please ensure that VirtualBox's DHCP server is not running,
otherwise the razor client nodes may recieve IP address in the
`192.168.0.0.` range:
```sh
VBoxManage list dhcpservers                          # should show no dhcp servers
VBoxManage dhcpserver remove --netname NETWORK_NAME  # otherwise, run this
```

Now clone this project repo to your workstation.

All you should have to type in the project directory is:

```sh
$ ./script/bootstrap
```

Follow any directions given and possibly re-run the bootstrap script.

## Usage

### Starting The Razor Node

```sh
$ vagrant up razor
```

## Starting The Chef Server (Optional)

```sh
$ vagrant up chef
```

## Starting The Puppet Master Server (Optional)

```sh
$ vagrant up puppet
```

### Setting Up A Sample Razor Configuration

To see Razor in action, several "slices" have to be set up in order to execute
a [policy][policy_wiki] on a [node][node_wiki]. Several quickstart examples
have been provided which will set up all nodes to install Ubuntu 12.04 LTS.
To run the script, login to the **razor** node and become the root user:

```sh
$ vagrant ssh razor
$ sudo su - root
```

#### Chef Broker Configuration

This will set up a Chef broker to run after nodes are provisioned. Run it
from the Vagrant-provided mount:

```sh
$ /vagrant/contrib/razor_for_chef_ubuntu.sh
```

For a list of configuration overrides (such as the ISO download URL), please
run:

```sh
$ /vagrant/contrib/razor_for_chef_ubuntu.sh help
```

#### Puppet Broker Configuration

This will set up a Puppet broker to run after nodes are provisioned. Run it
from the Vagrant-provided mount:

```sh
$ /vagrant/contrib/razor_for_puppet_ubuntu.sh
```

For a list of configuration overrides (such as the ISO download URL), please
run:

```sh
$ /vagrant/contrib/razor_for_puppet_ubuntu.sh help
```

#### Brokerless Configuration

This will set up a basic setup with no brokers running. Run it from the
Vagrant-provided mount:

```sh
$ /vagrant/contrib/razor_for_bare_ubuntu.sh
```

For a list of configuration overrides (such as the ISO download URL), please
run:

```sh
$ /vagrant/contrib/razor_for_bare_ubuntu.sh help
```

### Starting A Razor Client Node

```sh
$ vagrant up node1
```

There are by default 3 nodes available (i.e. **node1**, **node2**, **node3**),
but you can set a higher/lower number by setting `RAZOR_NODES=10` in your
shell environment:

```sh
$ export RAZOR_NODES=10
$ vagrant status
Current VM states:

razor                    running
chef                     not_created
puppet                   not_created
node1                    not created
node2                    not created
node3                    not created
node4                    not created
node5                    not created
node6                    not created
node7                    not created
node8                    not created
node9                    not created
node10                   not created

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

### Starting The Entire Cluster

```sh
$ vagrant up
```

## Vagrant Base Boxes

The base boxes were built with the [VeeWee][veewee_site] gem. The Razor and
Puppet nodes are using an [Opscode][opscode_site] provided Ubuntu 12.04 base
box, built from VeeWee definitions in a project called [Bento][bento_site]. To
simulate unprovisioned bare metal instances, a special base box called
[**blank-amd64**][blank_amd64] was created and was built from VeeWee
definitions in a project called [veewee-definitions][vwd_site].

## Development

* Source hosted at [GitHub][repo]
* Report issues/Questions/Feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make.

## <a name="license"></a> License and Author

Author:: [Fletcher Nichol][fnichol] (<fnichol@nichol.ca>)

Copyright 2012, Blue Box Group, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


[bento_site]:   https://github.com/opscode/bento
[blank_amd64]:  https://github.com/fnichol/veewee-definitions/blob/master/definitions/blank-amd64/definition.rb
[opscode_site]: http://www.opscode.com/
[node_wiki]:    https://github.com/puppetlabs/Razor/wiki/node
[policy_wiki]:  https://github.com/puppetlabs/Razor/wiki/policy
[vb_site]:      https://www.virtualbox.org/wiki/Downloads
[veewee_site]:  https://github.com/jedi4ever/veewee
[vagrant_site]: http://vagrantup.com/
[vagrant_berkshelf]: http://berkshelf.com/
[vagrant_omnibus]: https://github.com/schisamo/vagrant-omnibus
[vwd_site]:     https://github.com/fnichol/veewee-definitions

[fnichol]:      https://github.com/fnichol
[repo]:         https://github.com/blueboxgroup/razor-vagrant-lab
[issues]:       https://github.com/blueboxgroup/razor-vagrant-lab/issues
