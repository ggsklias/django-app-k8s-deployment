#!/bin/bash
source ./scripts/default_ansible.sh
ANSIBLE_CONFIG=$ANSIBLE_PATH/ansible.cfg ansible-playbook -i provision/ansible/inventory.ini provision/ansible/get_kube_config.yml
source ./scripts/default_helm.sh