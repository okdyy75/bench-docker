# Go

```
# ビルド＆実行
go run bench.go

# ベンチ実行
go build bench.go
./bench
```

## goポイント
- goではmainより先にinit関数が呼ばれる
- goでは例外がない(発生しない)ので関数の戻り値として返ってくるエラー(インターフェース)
をこちらで処理しなければならない

Goの日付フォーマットは特定の文字
```
// phpだと
echo (new DateTime)->format('Y-m-d H:i:s');

// goだと
println(time.Now().Format("2006-01-02 15:04:05"))
```

これが出たらぬるぽ
```
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x20 pc=0x4af101]
```


ローカル変数内で
一度定義したら代入するように記述する
```
	cmd = "TRUNCATE users;"
	_, err := db.Exec(cmd)
	if err != nil {
		panic(err)
	}

	cmd = "TRUNCATE posts;"
	_, err = db.Exec(cmd)
	if err != nil {
		panic(err)
	}
```

グローバル変数へ代入する場合は一度ローカル変数で受け取り、グローバル変数に渡す
```
	_dbc, err := sql.Open("mysql", dsn)
	dbc = _dbc
```


import次の記述について
```
import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
    // アンスコはソースコード内では使わなくても依存的に使われる際に書く
)

```