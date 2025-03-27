#!/bin/bash
./default_ansible.sh
ansible-playbook -i inventory.ini get_kube_config.yml
./default_helm.sh