#!/bin/bash
./scripts/default_ansible.sh
ansible-playbook -i inventory.ini get_kube_config.yml
./scripts/default_helm.sh