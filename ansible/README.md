
# Ansible

```
# ec2に入る
dc exec ec2 sh

# ansible実行
ec2# ansible-playbook -i localhost, -c local site.yml

# 特定のロールのみ実行する場合
ec2# ansible-playbook -i localhost, -c local --tags "common,mysql,php" site.yml

# env反映
ec2# source ~/.bash_profile

```

いつも忘れる
```
systemctl start mysqld.service
systemctl status mysqld.service

systemctl start nginx.service
systemctl status nginx.service

systemctl start php-fpm.service
systemctl status php-fpm.service

```
