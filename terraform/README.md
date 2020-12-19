# Terraform

## awsのconfigを設定しておく
```
> aws configure --profile dev-user
AWS Access Key ID [None]: XXXXXXXXXXXXXXXX
AWS Secret Access Key [None]: XXXXXXXXXXXXXXXX
Default region name [None]: ap-northeast-1
Default output format [None]: json

cat ~/.aws/config

# dev-userを使用
export AWS_DEFAULT_PROFILE=dev-user
```

## EC2で使う鍵を作成しておく
```
mkdir .ssh
ssh-keygen -f .ssh/xxxx
```

## Terraform実行
```
# init
terraform init

# 計画
terraform plan -var-file=dev.tfvars

# デプロイ
terraform apply -var-file=dev.tfvars

# 破棄
terraform destroy -var-file=dev.tfvars
```

## terraform + ansible
```
# terraformで作ったEC2に対してansible実行
ansible-playbook -i hosts ../ansible/site.yml --private-key=./.ssh/xxxxx

# ssh
ssh -i ./.ssh/xxxxx  ec2-user@xxx.xxx.xxx.xxx

# rootに切り替え
sudo su -
source ~/.bash_profile

# bench実行

```