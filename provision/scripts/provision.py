import subprocess
import re
import os, sys
from pathlib import Path

TERRAFORM_DIR = ""
ANSIBLE_DIR = ""
INVENTORY_INI_DIR = ""
FOLDER_LIST = ["terraform", "ansible"]


def find_dir_in_current_or_parent(folder_name):
    # Get the current working directory
    cwd = Path.cwd()
    
    candidate = cwd / folder_name
    if candidate.exists() and candidate.is_dir():
        return candidate.resolve()
    
    # Otherwise, check in the parent directory
    parent_candidate = cwd.parent / folder_name
    if parent_candidate.exists() and parent_candidate.is_dir():
        return parent_candidate.resolve()

    # Folder not found in either location
    return None

for folder in FOLDER_LIST:
    result = find_dir_in_current_or_parent(folder)
    if result:
        if "terraform" in result.as_posix():
            TERRAFORM_DIR = result.as_posix()
        elif "ansible" in result.as_posix():
            ANSIBLE_DIR = result.as_posix()
            INVENTORY_INI_DIR = ANSIBLE_DIR + "/" + "inventory.ini"

def check_environ():
    # Check if AWS credentials are set
    if all(key not in os.environ for key in ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]):
        print("AWS credentials not set. Exiting...")
        sys.exit(1)
    else:
        print("AWS credentials set. Proceeding...")

def run_terraform():
    # Run Terraform and capture output
    tf_command = ["terraform", "-chdir=%s" % TERRAFORM_DIR, "apply", "-auto-approve"]
    process = subprocess.run(tf_command, text=True, capture_output=True)
    output = process.stdout

    # Extract IP addresses using regex
    ips = re.findall(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', output)

    # Get the last two IPs
    last_two_ips = ips[-2:] if len(ips) >= 2 else ips
    return last_two_ips


def read_inventory_and_update(inventory):
    with open(INVENTORY_INI_DIR, "r") as file:
        inventory = file.readlines()

    updated_inventory = []
    for line in inventory:
        if line.startswith("[master]"):
            updated_inventory.append("[master]\n")
            updated_inventory.append(f"{master_ip} ansible_user=ec2-user\n")
        elif line.startswith("[workers]"):
            updated_inventory.append("[workers]\n")
            updated_inventory.append(f"{worker_ip} ansible_user=ec2-user\n")
        elif all(string not in line for string in ["[master]", "[workers]", "ansible_user"]):
            updated_inventory.append(line)
    
    return updated_inventory

def write_to_inventory(inventory):
    if inventory:
        with open(INVENTORY_INI_DIR, "w") as file:
            file.writelines(inventory)
    else:
        raise ValueError("Inventory is empty")

check_environ()

last_two_ips = run_terraform()

master_ip = last_two_ips[0]
worker_ip = last_two_ips[1]

updated_inventory = read_inventory_and_update(INVENTORY_INI_DIR)

write_to_inventory(updated_inventory)

# Print the IPs
print("\n".join(last_two_ips))


