variable "boot_wait" {
  type    = string
  default = "10s"
}

variable "iso_checksum" {
  type    = string
  default = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/22.04/ubuntu-22.04.2-live-server-amd64.iso"
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

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

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

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
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
