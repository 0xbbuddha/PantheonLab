#!/bin/bash
cd vagrant/dc01; vagrant destroy -f && vagrant up && cd ../enfers && vagrant destroy -f && vagrant up; cd ../../ && ansible-playbook -i ansible/inventory/administrator_inventory.yml ansible/playbooks/windows_main.yml
