# Localhost Love With Packer + Ansible + Vagrant
## Overview
Do you find yourself having trouble testing server updates?
Or do you just want to build a server?
Or do you just want to get in to DevOps and don't really know
how to decipher all of the jargon? Then this is the 
perfect starting point for you. This blog post is going to
be dedicated to bringing the cloud to you by combining
a few extremeley useful tools:

* Packer
* Ansible
* Vagrant

We are going to use packer and ansible together to build a base
NGINX Ubuntu image. Next, we are going to use vagrant to deploy it
and test it out!

For the sake of this post, I will assume that packer, ansible, and vagrant
are installed on your machine. If they aren't, follow the links below:

* [Packer Installation](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)
* [Ansible Installation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* [Vagrant Installation](https://www.vagrantup.com/docs/installation)

## File Structure
First, let's look at the layout of our files. From the top level:

```shell
packer-vagrant-ansible % ls -l
total 8
-rw-r--r--  1 alex  staff  175 Jun  8 13:52 README.md
drwxr-xr-x  5 alex  staff  160 Jun  7 20:43 ansible
drwxr-xr-x  5 alex  staff  160 Jun  8 13:57 packer
drwxr-xr-x  2 alex  staff   64 Jun  7 15:51 vagrant
packer-vagrant-ansible % 
```

We see that we have three directories, one for each tool. The 
`ansible` directory will be dedicated to any `ansible` files, tasks, etc.
The `packer` directory will have our `packer` build file and any associated
preseed/unattended install files. `vagrant` will then house our `Vagrantfile`
and anything else the booted box will need!

## Better Building With Packer + Ansible
### Packer
Great, now we can get started. Let's navigate into the `packer/` directory
and look in our `ubuntu-server.pkr.hcl` file.

The first thing we notice are a whole bunch of variables:

```shell
variable "boot_wait" {
  type    = string
  default = "10s"
}

variable "iso_checksum" {
  type    = string
  default = "84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "memory" {
  type    = string
  default = "4096"
}

variable "ssh_password" {
  type    = string
  default = "packer"
}

variable "ssh_timeout" {
  type    = string
  default = "15m"
}

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_handshake_attempts" {
  type    = number
  default = 75
}
```

Variables are things that you can define at build time and are great
for keeping secrets out of your repository. For example, if `ssh_password`
was truly secret, we could override the default value like so:

```shell
prompt> packer build ./ubuntu-server.pkr.hcl -var 'ssh_password=sup3rs3cr3t'
```

and packer would substitute any references to `${var.ssh_password}` to `sup3rs3cr3t`!

Moving down, we will see our `locals` block. 

```shell
# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }
```

`locals` are also variables in a sense, but they
are not user given. They are composed of function calls, string concatenations, etc. and can
be referenced similarly to variables. For example, we could reference `${local.timestamp}` 
throughout our `packer` file.

The meat comes next, which is our `source` block. It looks scary, so jump down a few 
lines and we are going to break this up line-by-line.

```shell
source "virtualbox-iso" "vbox" {
  guest_os_type          = "Ubuntu_64"
  shutdown_command       = "echo 'packer' | sudo -S shutdown -P now"
  ssh_password           = "${var.ssh_password}"
  ssh_timeout            = "${var.ssh_timeout}"
  ssh_username           = "${var.ssh_username}"
  ssh_handshake_attempts = "${var.ssh_handshake_attempts}"
  cpus                   = "${var.cpus}"
  memory                 = "${var.memory}"
  boot_wait              = "${var.boot_wait}"
  http_directory         = "http"
  iso_url                = "${var.iso_url}"
  iso_checksum           = "${var.iso_checksum}"

  boot_command = [
    "<esc><esc><esc><esc>e<wait>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<enter><wait>",
    "initrd /casper/initrd<enter><wait>", "boot<enter>", "<enter><f10><wait>"
  ]
}
```

The `source` blocks define the configuration for our source plugin(s), and you can have multiple
in your `packer` file. If we look at our `source` block, we see that we will be defining
a `source` of type `virtualbox-iso` and we will be naming is `vbox`. From a high level, 
this means we are telling packer that we are going to building a VirtualBox VM from an ISO
image. The rest also looks scary, but we are going to demystify it.

The first few blocks aren't too bad:

```shell
  guest_os_type          = "Ubuntu_64"
  shutdown_command       = "echo 'packer' | sudo -S shutdown -P now"
  ssh_password           = "${var.ssh_password}"
  ssh_timeout            = "${var.ssh_timeout}"
  ssh_username           = "${var.ssh_username}"
  ssh_handshake_attempts = "${var.ssh_handshake_attempts}"
  cpus                   = "${var.cpus}"
  memory                 = "${var.memory}"
  boot_wait              = "${var.boot_wait}"
  http_directory         = "http"
  iso_url                = "${var.iso_url}"
  iso_checksum           = "${var.iso_checksum}"
```

This means we are:

* creating an Ubuntu 64-Bit machine (`guest_os_type`)
* using `echo 'packer' | sudo -S shutdown -P now` when we halt our machine after provisioning (`shutdown_command`)
* setting the SSH Password for packer to use to our previously noted variable (`ssh_password`)
* setting the SSH Time for packer to use to our previously noted variable (`ssh_timeout`)
* setting the SSH Username for packer to use to our previously noted variable (`ssh_username`)
* setting the Maximum number SSH Handshake attempts for packer to 
  try before reporting an error (`ssh_handshake_attempts`)
* setting the SSH Time for packer to use to our previously noted variable (`ssh_wait_timeout`)
* setting the number of CPUs for our packer machine (`cpus`)
* setting the number of memory for our packer machine (`memory`)
* how long packer should wait until typing to boot commands (`boot_wait`)
* where packer should serve automated install files from (`http_directory`)
* which iso packer should use for this image (`iso_url` and `iso_checksum`)

The next part is a little more daunting:

```shell
  boot_command = [
    "<esc><esc><esc><esc>e<wait>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<enter><wait>",
    "initrd /casper/initrd<enter><wait>", "boot<enter>", "<enter><f10><wait>"
  ]

```

This part is better described with a video/gif, so I have attached one below. But, we
are literally going to have packer hit the escape button four times, then hit the delete button a bunch of times
and then type the following commands
```shell
linux /casper/vmlinuz --- autoinstall ds="nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/"
initrd /casper/initrd
boot
```

The `HTTPIP` and `HTTPPort` variables are dynamically set by packer as it creates an HTTP server to serve
files to the booted box.

In all, this is going to tell the automated installation process where to find the install files and how to boot on up!

Finally, we can enter our `build` block which tells packer which sources to build, in what
formats, and with which post processors:

```shell
build {
  sources = ["source.virtualbox-iso.vbox"]


  provisioner "ansible" {
    playbook_file = "../ansible/site.yml"
  }

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      provider_override   = "virtualbox"
    }
  }
}
```

In this block, we tell ansible to build our crazy `source` block, provision it with our ansible
playbook, and then output to it a vagrant box format.

### Ansible
The scariest part is done. Ansible is just friendly ole yaml!

In the `ansible` directory, you'll see the following file structure:

```yaml
packer-vagrant-ansible % ls -l
total 8
drwxr-xr-x  4 alex  staff  128 Jun  7 20:42 files
-rw-r--r--  1 alex  staff  438 Jun  8 10:25 site.yml
drwxr-xr-x  4 alex  staff  128 Jun  7 20:34 tasks
```

Our main entrypoint will be `site.yml`, our static files will reside
in the `files/` directory, and any tasks will fall in our `tasks` directory.

Let's first look at our `site.yml` file:

```yaml
---
# -------------------------------------
# Packer Provisioning Tasks
# These tasks get called by packer
# via the provisioner block
# -------------------------------------
- name: Packer Provisioning Playbook
  hosts: all
  gather_facts: true

  tasks:
    - name: Run apt related tasks
      become: true
      import_tasks: tasks/apt.yml
    
    - name: Run nginx related tasks
      become: true
      import_tasks: tasks/nginx.yml
```

Super easy and super clean! Its just going to pull in two task sets, `apt` and `nginx`. We will
first look at the `apt` task set:

```yaml
---
# -------------------------------------
# Apt Tasks
# Tasks to:
#   * Update Packages
#   * Install New Packages
#   * Clean up unneeded packages
# -------------------------------------

- name: Update and upgrade apt packages
  apt:
    upgrade: true
    update_cache: true

- name: apt install the required packages
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - ufw

- name: Remove useless packages from the cache
  apt:
    autoclean: true
    autoremove: true
```

Again, this is a pretty simple task set where we just:

* Run an `apt-get update`
* Run an `apt-get install nginx ufw`
* Run an `apt-get autoremove` and `apt-get autoclean`

And yes, the `nginx` one is just as simple:

```yaml
---
# -------------------------------------
# NGINX Tasks
# Tasks to:
#   * Update default files for nginx
#   * Restart and enable NGINX
# -------------------------------------
- name: copy the default nginx files
  copy:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"

  loop:
    - src: files/default-index.html
      dest: /usr/share/nginx/html/index.html
    - src: files/default-nginx.conf
      dest: /etc/nginx/nginx.conf

- name: start nginx and enable it for reboot
  service:
    name: nginx
    state: started
    enabled: true
```

All we do here is:

* Copy files from our `files` dir to a location in the packer image
* Restart and enable nginx

### Building
Finally, to build your image you can just run the packer
command:

```shell
prompt> packer build ./ubuntu-server.pkr.hcl
virtualbox-iso.vbox: output will be in this color.

==> virtualbox-iso.vbox: Retrieving Guest additions
==> virtualbox-iso.vbox: Trying /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso
==> virtualbox-iso.vbox: Trying /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso
==> virtualbox-iso.vbox: /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso => /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso
==> virtualbox-iso.vbox: Retrieving ISO
==> virtualbox-iso.vbox: Trying https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso
==> virtualbox-iso.vbox: Trying https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso?checksum=sha256%3A84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f
==> virtualbox-iso.vbox: https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso?checksum=sha256%3A84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f => /Users/alex/.cache/packer/b9441068de828d36573e1274dfe77f69aebda15a.iso
==> virtualbox-iso.vbox: Starting HTTP server on port 8040
==> virtualbox-iso.vbox: Creating virtual machine...
==> virtualbox-iso.vbox: Creating hard drive output-vbox/packer-vbox-1655083928.vdi with size 40000 MiB...
==> virtualbox-iso.vbox: Mounting ISOs...
    virtualbox-iso.vbox: Mounting boot ISO...
==> virtualbox-iso.vbox: Creating forwarded port mapping for communicator (SSH, WinRM, etc) (host port 3081)
==> virtualbox-iso.vbox: Starting the virtual machine...
==> virtualbox-iso.vbox: Waiting 10s for boot...
==> virtualbox-iso.vbox: Typing the boot command...
==> virtualbox-iso.vbox: Using SSH communicator to connect: 127.0.0.1
==> virtualbox-iso.vbox: Waiting for SSH to become available...
==> virtualbox-iso.vbox: Connected to SSH!
==> virtualbox-iso.vbox: Uploading VirtualBox version info (6.1.34)
==> virtualbox-iso.vbox: Uploading VirtualBox guest additions ISO...
==> virtualbox-iso.vbox: Provisioning with Ansible...
    virtualbox-iso.vbox: Setting up proxy adapter for Ansible....
==> virtualbox-iso.vbox: Executing Ansible: ansible-playbook -e *****_build_name="vbox" -e *****_builder_type=virtualbox-iso -e *****_http_addr=10.0.2.2:8040 --ssh-extra-args '-o IdentitiesOnly=yes' -e ansible_ssh_private_key_file=/var/folders/j1/pzz6h6g153qfmr0yxwdr3xd80000gn/T/ansible-key1630680445 -i /var/folders/j1/pzz6h6g153qfmr0yxwdr3xd80000gn/T/*****-provisioner-ansible116608262 /Users/alex/my-code/*****-vagrant-ansible/ansible/site.yml
.
.
ansible logging
.
.
==> virtualbox-iso.vbox: Gracefully halting virtual machine...
==> virtualbox-iso.vbox: Preparing to export machine...
    virtualbox-iso.vbox: Deleting forwarded port mapping for the communicator (SSH, WinRM, etc) (host port 3081)
==> virtualbox-iso.vbox: Exporting virtual machine...
    virtualbox-iso.vbox: Executing: export packer-vbox-1655083928 --output output-vbox/packer-vbox-1655083928.ovf
==> virtualbox-iso.vbox: Cleaning up floppy disk...
==> virtualbox-iso.vbox: Deregistering and deleting VM...
==> virtualbox-iso.vbox: Running post-processor:  (type vagrant)
==> virtualbox-iso.vbox (vagrant): Creating a dummy Vagrant box to ensure the host system can create one correctly
==> virtualbox-iso.vbox (vagrant): Creating Vagrant box for 'virtualbox' provider
    virtualbox-iso.vbox (vagrant): Copying from artifact: output-vbox/packer-vbox-1655083928-disk001.vmdk
    virtualbox-iso.vbox (vagrant): Copying from artifact: output-vbox/packer-vbox-1655083928.ovf
    virtualbox-iso.vbox (vagrant): Renaming the OVF to box.ovf...
    virtualbox-iso.vbox (vagrant): Compressing: Vagrantfile
    virtualbox-iso.vbox (vagrant): Compressing: box.ovf
    virtualbox-iso.vbox (vagrant): Compressing: metadata.json
    virtualbox-iso.vbox (vagrant): Compressing: packer-vbox-1655083928-disk001.vmdk
Build 'virtualbox-iso.vbox' finished after 12 minutes 27 seconds.

```

## Easy Deployments With Vagrant
Now that we have everything built, we can run it all!

First, we need to add the box to our inventory. This means
that we will place the box in a location that vagrant can find and
reference it.

```shell
# Assumes running from vagrant directory
prompt> cd vagrant/
prompt> vagrant box add --force "devops-fun" "${PWD}/../packer/packer_vbox_virtualbox.box"
```

Our vagrant file will then tell Vagrant which image to use, any hypervisor settings,
etc. Ours is going to be VERY simple:

```ruby
Vagrant.configure("2") do |config|
  
  # Name of our newly created box
  config.vm.box = "devops-fun"

  # Create a forwarded port so that we can view the NGINX host from our local
  # machine on port 8080
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
  end
end
```

The above Vagrantfile tells Vagrant to:

* Use our added `devops-fun` image
* Forward traffic from `127.0.0.1:8080` to our Vagrant box on port `80`
* Enable the GUI on VirtualBox so we can see the boot process

And then once the box was added, we can run it!

```shell
# Assumes running from vagrant directory
prompt> cd vagrant/
# Optional if you want to use VB-Guest
prompt> vagrant plugin install vagrant-vbguest
prompt> vagrant up
```

Let's do a quick check to make sure we can both cURL and view our
NGINX webpage:

* Open a Browser and go to `http://127.0.0.1:8080`
* You should see a page similar to the below

Or if you prefer a terminal:

```shell
prompt> curl localhost:8080
<h2>Hello From Ansible!!!</h2>                                                                                                                                                                                  
```