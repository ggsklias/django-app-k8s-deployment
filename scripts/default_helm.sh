#!/bin/bash
ls -la
curl -L https://get.helm.sh/helm-v3.9.0-linux-x86_64.tar.gz -o helm.tar.gz
ls -la
tar -zxvf helm.tar.gz
ls -la
mv linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
helm version --short