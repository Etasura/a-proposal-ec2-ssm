#!/bin/bash
set -euxo pipefail

# 更新 & Nginx
dnf -y update
dnf -y install nginx

# インスタンスID取得（IMDSv2）
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
IID=$(curl -sS -H "X-aws-ec2-metadata-token: ${TOKEN}" "http://169.254.169.254/latest/meta-data/instance-id")

cat >/usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html lang="ja"><head><meta charset="utf-8"><title>Hello from EC2</title></head>
<body style="font-family:sans-serif;margin:3rem">
<h1>EC2 Minimal (SSM Only)</h1>
<p>Instance ID: <code>${IID}</code></p>
<p>AMI: Amazon Linux 2023</p>
<p>Provisioned by Terraform</p>
</body></html>
EOF

systemctl enable nginx
systemctl start nginx
