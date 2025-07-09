#!/bin/bash
cd vagrant && vagrant up && cd .. && ansible-playbook -i ansible/inventory/administrator_inventory.yml ansible/playbooks/windows_main.yml
