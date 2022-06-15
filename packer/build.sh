#!/bin/bash

rm -rf output-vbox packer_vbox_virtualbox.box *.log

packer build ./ubuntu-server.pkr.hcl

vagrant box add --force "devops-fun" "${PWD}/packer_vbox_virtualbox.box"