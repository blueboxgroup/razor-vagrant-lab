# Razor Vagrant Lab

## Initial Setup

Download and install the following on your workstation:

1. [VirtualBox][vb_site] (currently tested on version 4.2.4 on Mac)
2. [VirtualBox Oracle VM VirtualBox Extension Pack][vb_site] (needed for
   PXE booting support)
3. [Vagrant][vagrant_site] (package install is suggested)

Now clone this project repo to your workstation.

All you should have to type in the project directory is:

```sh
$ ./script/bootstrap
```

Follow any directions given and possibly re-run the bootstrap script.

## Starting The Razor Node

```sh
$ vagrant up razor
```

## Starting A Razor Client Node

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

## Starting The Entire Cluster

```sh
$ vagrant up
```

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


[vb_site]:      https://www.virtualbox.org/wiki/Downloads
[vagrant_site]: http://vagrantup.com/

[fnichol]:      https://github.com/fnichol
[repo]:         http://bluebox.net
[issues]:       http://bluebox.net
