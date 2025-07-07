#!/bin/bash
cd vagrant/olympe && vagrant destroy -f && vagrant up && cd ../dc01 && vagrant destroy -f && vagrant up && cd ../enfers && vagrant destroy -f && vagrant up && cd ../../ && ansible-playbook -i ansible/inventory/linux_inventory.yml ansible/playbooks/linux_wordpress.yml && ansible-playbook -i ansible/inventory/administrator_inventory.yml ansible/playbooks/windows_main.yml



