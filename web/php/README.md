# PHP

```
# ベンチ実行
php bench.php
```

```
# mysqlオプション実行。※ec2でやる必要あり
dc exec ec2 bash -l

ec2# ansible-playbook -i localhost, -c local --tags "common,mysql,php" site.yml

ec2# php mysql_option.php
```

```
-- テーブル削除
DROP TABLE IF EXISTS `users`
```