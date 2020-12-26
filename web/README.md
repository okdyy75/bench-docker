

## bench.sh
```
sh bench.sh --lang=go --count=10
```

## テストデータ作成方法

100万件作る場合

```sql

-- usersテーブルリセット
truncate users;

-- インサート
insert into users (
    name, email, email_verified_at, password, remember_token, created_at, updated_at
)
select
  concat('名前', t.ROWNUM) as name,
  concat('test',t.ROWNUM, '@example.com') as email,
  now() as email_verified_at,
  SHA1(t.ROWNUM) as password,
  SUBSTRING(MD5(RAND()), 1, 10) as remember_token,
  now() as created_at,
  now() as updated_at
from (
  select (@ROWNUM := @ROWNUM + 1) as ROWNUM, t1.*
  from
    (select @ROWNUM:=0) r,
    (select 1 union all select 1 union all select 1 union all select 1) t1,
    (select 1 union all select 1 union all select 1 union all select 1) t2,
    (select 1 union all select 1 union all select 1 union all select 1) t3,
    (select 1 union all select 1 union all select 1 union all select 1) t4,
    (select 1 union all select 1 union all select 1 union all select 1) t5,
    (select 1 union all select 1 union all select 1 union all select 1) t6,
    (select 1 union all select 1 union all select 1 union all select 1) t7,
    (select 1 union all select 1 union all select 1 union all select 1) t8,
    (select 1 union all select 1 union all select 1 union all select 1) t9,
    (select 1 union all select 1 union all select 1 union all select 1) t10
) t
order by t.ROWNUM limit 1000000;

```


作成データ

```
'1','名前1','test1@example.com','2020-12-26 18:37:18','356a192b7913b04c54574d18c28d46e6395428ab','dd8512ee96','2020-12-26 18:37:18','2020-12-26 18:37:18'
'2','名前2','test2@example.com','2020-12-26 18:37:18','da4b9237bacccdf19c0760cab7aec4a8359010b0','dcc1a3cc4b','2020-12-26 18:37:18','2020-12-26 18:37:18'
'3','名前3','test3@example.com','2020-12-26 18:37:18','77de68daecd823babbb58edb1c8e14d7106e83bb','d1b95881bc','2020-12-26 18:37:18','2020-12-26 18:37:18'
'4','名前4','test4@example.com','2020-12-26 18:37:18','1b6453892473a467d07372d45eb05abc2031647a','755311a18b','2020-12-26 18:37:18','2020-12-26 18:37:18'
'5','名前5','test5@example.com','2020-12-26 18:37:18','ac3478d69a3c81fa62e60f5c3696165a4e5e6ac4','cd9d50049a','2020-12-26 18:37:18','2020-12-26 18:37:18'
```

100万件でworkbenchのcsvエクスポートが大体3分くらい