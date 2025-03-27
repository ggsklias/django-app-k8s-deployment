#!/bin/bash
source ./scripts/default_ansible.sh
ansible-playbook -i inventory.ini get_kube_config.yml
ls -l 
cd ../../
source ./scripts/default_helm.sh