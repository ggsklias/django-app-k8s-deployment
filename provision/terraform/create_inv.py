#!/usr/bin/env python3
import json
import subprocess

def get_terraform_output():
    with open("output.json", "r") as f:
        return json.load(f)

def generate_inventory(outputs, inventory_file="../ansible/inventory.ini"):
    masters = outputs["public_ip_master"]["value"]
    workers = outputs["public_ip_worker"]["value"]
    nginx = outputs["public_ip_nginx"]["value"]

    with open(inventory_file, "w") as f:
        f.write("[master]\n")
        for idx, ip in enumerate(masters, start=1):
            if idx == 1:
                f.write(f"master{idx} ansible_host={ip} ansible_user=ec2-user role=primary\n")
            else:
                f.write(f"master{idx} ansible_host={ip} ansible_user=ec2-user role=secondary\n")
        f.write("\n[workers]\n")
        for idx, ip in enumerate(workers, start=1):
            f.write(f"worker{idx} ansible_host={ip} ansible_user=ec2-user\n")
        f.write("\n[nginx]\n")
        for idx, ip in enumerate(nginx, start=1):
            f.write(f"nginx{idx} ansible_host={ip} ansible_user=ec2-user\n")
        # Optionally, add group variables:
        f.write("\n[all:vars]\n")
        f.write("ansible_ssh_private_key_file=./ssh_key.pem\n")

if __name__ == "__main__":
    tf_outputs = get_terraform_output()
    generate_inventory(tf_outputs)
    print("inventory.ini generated successfully.")
