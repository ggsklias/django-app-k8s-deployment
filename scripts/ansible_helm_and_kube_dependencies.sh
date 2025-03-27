#!/bin/bash
source ./scripts/default_ansible.sh
ansible-playbook -i provision/ansible/inventory.ini provision/ansible/get_kube_config.yml
source ./scripts/default_helm.sh