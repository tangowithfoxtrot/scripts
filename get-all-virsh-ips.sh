#!/usr/bin/env bash

for network in $(sudo virsh net-list | awk 'NR>1' | grep '[a-zA-Z].*' | awk '{ print $1 }'); do
    sudo virsh net-dhcp-leases $network | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])'
done