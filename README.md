　EC2 × SSM × user_data（最小Web）にて構成

## 目的
- **SSHゼロ運用**（22/tcp閉鎖）で **SSM(Session Manager)** を体験
- `user_data` で Nginx を自動セットアップ
- Terraform により **起動→検証→破棄** を再現可能に

## 構成
- VPC: Default VPC / Default Subnet
- EC2: t3.micro / Amazon Linux 2023
- IAM: インスタンスロールに `AmazonSSMManagedInstanceCore`
- SG: 80/tcp のみ許可（0.0.0.0/0）、SSHは閉鎖
- 起動スクリプト: `user_data.sh`（Nginx導入、インスタンスID表示ページ生成）

## 使い方
```bash
terraform init
terraform apply -auto-approve
# 出力: public_ip / public_dns / instance_id
# 表示確認
curl -I http://<public_ip>
# SSM接続（事前に Session Manager Plugin をインストール）
aws ssm start-session --target $(terraform output -raw instance_id)
# 後片付け
terraform destroy -auto-approve
```

## 動作確認コマンド（SSM内）
```bash
systemctl status nginx
sudo ss -ltnp | grep :80
sudo tail -n 100 /var/log/cloud-init-output.log
```

## セキュリティの意図
- インバウンドは80のみ。管理は **SSM経由**（鍵・踏み台不要、操作はIAM/CloudTrailで統制可能）
- `user_data` は IMDSv2 を用いたメタデータ参照で記述

## コスト配慮
- t3.micro、CPUクレジットは **standard**（Unlimited課金を防止）
- **秒課金**のため検証後すぐ `destroy`（EBSも削除）

## 既知の落とし穴
- AL2023のAMIは **ルートボリューム既定が30GiB** → `root_block_device` の `volume_size >= 30`
- Default VPC が無い環境ではエラー → 自前VPC構成に切替が必要

## 将来拡張
- 自前VPC（/24×2AZ）、ALB化、CloudWatch Agent＋アラーム、CI（fmt/validate/plan + tfsec/Checkov）
- Graviton版（t4g.micro + arm64 AMI）
