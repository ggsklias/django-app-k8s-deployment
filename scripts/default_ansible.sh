#!/bin/bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
aws s3 cp s3://$AWS_BUCKET_NAME/ansible/inventory.ini provision/ansible/inventory.ini
chmod 755 provision/ansible
cd provision/ansible
echo "$SSH_PRIVATE_KEY" > ssh_key.pem
chmod 600 ssh_key.pem