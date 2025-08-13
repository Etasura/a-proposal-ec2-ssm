# A案: EC2 × SSM × user_data（最小Web）

## 目的
- **SSHゼロ運用**（22/tcp閉鎖）で **SSM (Session Manager)** の運用体験
- `user_data` で Nginx を自動セットアップし、**起動→検証→破棄**を IaC で再現可能に
- 面接で語れる「安全・最小・再現性」の実例

## 構成
- **VPC**: Default VPC / Default Subnet（工数最小）
- **EC2**: `t3.micro` / **Amazon Linux 2023**
- **IAM**: インスタンスロール `AmazonSSMManagedInstanceCore`
- **SG**: 80/tcp のみ許可（デモのため公開）※SSHは閉鎖
- **user_data**: Nginx導入と、インスタンスIDを表示する簡易ページ生成

## セキュリティ設計の意図
- **SSH禁止 & SSM運用**: 鍵不要・踏み台不要。IAM/CloudTrailで統制可能
- **IMDSv2必須化**: `metadata_options.http_tokens = "required"`
- **EBS暗号化**: ルートボリューム `encrypted = true`
- **公開80/tcp**: 最小デモのため意図的に公開  
  実務では **ALB/WAF 経由や特定CIDR制限、VPCエンドポイント** で閉域化

## 使い方
```bash
terraform init
terraform apply -auto-approve
# 出力: public_ip / public_dns / instance_id
# 表示確認
curl -I http://<public_ip>
# SSM接続（Session Manager Plugin 必要）
aws ssm start-session --target $(terraform output -raw instance_id)
# 後片付け（秒課金対策）
terraform destroy -auto-approve
```

## 動作確認コマンド（SSM内）
```bash
systemctl is-active nginx   # => active
sudo ss -ltnp | grep :80
sudo tail -n 100 /var/log/cloud-init-output.log
```

## スキャン（tfsec）
このプロジェクトは **最小公開Webのデモ**のため、以下2件は理由付きで抑制しています。
- `aws-ec2-no-public-ingress-sgr`（80/tcp公開）
- `aws-ec2-no-public-egress-sgr`（OS更新/SSMのため送信許可）

設定ファイル: `.tfsec.yaml`（または `.tfsec.yml`）  
実行:
```bash
tfsec --config-file .tfsec.yaml .
```

## 既知の落とし穴と対処
- **AL2023のAMIはルートが 30GiB 相当** → ルートボリュームは `>= 30GiB`
- **Default VPC が無い環境** → 自前VPC構成が必要
- **Windows の端末で改行やロケール差** → `LANG=C` で英語化するとログの文字化け回避

## コスト配慮
- `t3.micro` + **CPUクレジット standard**（Unlimited課金を防止）
- **秒課金**なので検証後はすぐ `destroy`（EBSも削除）

## 将来拡張
- 自前VPC（/24×2AZ）／**ALB化**（EC2直公開→ALB背面）
- **Graviton版**（t4g.micro + arm64 AMI）
- **VPCE(SSM/EC2Messages/SSMMessages)** で完全閉域接続
- **CI**で `fmt/validate/tfsec` を自動化（本README下のCI参照）
