import subprocess
import re
import os, sys

def check_environ():
    # Check if AWS credentials are set
    if all(key not in os.environ for key in ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]):
        print("AWS credentials not set. Exiting...")
        sys.exit(1)
    else:
        print("AWS credentials set. Proceeding...")

def run_terraform():
    # Run Terraform and capture output
    process = subprocess.run(["terraform", "apply", "-auto-approve"], text=True, capture_output=True)
    output = process.stdout

    # Extract IP addresses using regex
    ips = re.findall(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', output)

    # Get the last two IPs
    last_two_ips = ips[-2:] if len(ips) >= 2 else ips

    return last_two_ips

check_environ()

last_two_ips = run_terraform()

master_ip = last_two_ips[0]
worker_ip = last_two_ips[1]
# Print the IPs
print("\n".join(last_two_ips))

with open("inventory.ini", "r") as file:
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

# Step 5: Write back the updated inventory
with open("inventory.ini", "w") as file:
    file.writelines(updated_inventory)

