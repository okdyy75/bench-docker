package main

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"os"
	"runtime"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

var dbc *sql.DB

func getDB() *sql.DB {

	if dbc != nil {
		return dbc
	}

	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "127.0.0.1"
	}
	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "3306"
	}
	name := os.Getenv("DB_NAME")
	if name == "" {
		name = "db"
	}
	user := os.Getenv("DB_USER")
	if user == "" {
		user = "root"
	}
	password := os.Getenv("DB_PASSWORD")
	if password != "" {
		password = ":" + password
	}

	dsn := fmt.Sprintf(
		"%s%s@tcp(%s:%s)/%s?charset=utf8&parseTime=true",
		user, password, host, port, name)

	_dbc, err := sql.Open("mysql", dsn)
	dbc = _dbc
	if err != nil {
		panic(err)
	}

	return _dbc
}

func initialize() {
	var cmd string

	db := getDB()

	cmd = `
		CREATE TABLE IF NOT EXISTS users (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			name varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
			email varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
			email_verified_at timestamp NULL DEFAULT NULL,
			password varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
			remember_token varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
			created_at timestamp NULL DEFAULT NULL,
			updated_at timestamp NULL DEFAULT NULL,
			PRIMARY KEY (id),
			UNIQUE KEY users_email_unique (email)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	`
	_, err := db.Exec(cmd)
	if err != nil {
		panic(err)
	}

	cmd = "TRUNCATE users;"
	_, err = db.Exec(cmd)
	if err != nil {
		panic(err)
	}

	// var cnt int
	// err = db.QueryRow("select count(*) as cnt from users;").Scan(&cnt)
	// println(cnt)

}

// User ユーザー情報
type User struct {
	ID              int
	Name            string
	Email           string
	EmailVerifiedAt time.Time
	Password        string
	RememberToken   string
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func work() {
	var (
		err    error
		file   *os.File
		reader *csv.Reader
		lines  []string
		line   string
		rows   *sql.Rows
	)

	db := getDB()

	// CSV読み込み
	println(time.Now().Format("2006-01-02 15:04:05.000000") + " import CSV start")
	file, err = os.Open("../import_users.csv")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	reader = csv.NewReader(file)
	_, err = reader.Read() // ヘッダースキップ
	for {
		lines, err = reader.Read()
		if err != nil {
			break
		}

		// lines[0]はidのため1から
		_, err = db.Exec(`
			INSERT INTO users (
				name,
				email,
				email_verified_at,
				password,
				remember_token,
				created_at,
				updated_at
			) values (
				?, ?, ?, ?, ?, ?, ?
			);
		`, lines[1], lines[2], lines[3], lines[4], lines[5], lines[6], lines[7])
		if err != nil {
			panic(err)
		}
	}
	println(time.Now().Format("2006-01-02 15:04:05.000000") + " import CSV end")

	rows, err = db.Query("select * from users order by id")
	if err != nil {
		panic(err)
	}

	// CSV書き出し
	println(time.Now().Format("2006-01-02 15:04:05.000000") + " export CSV start ")

	file, err = os.Create("./export_users.csv")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	// ヘッダー書き込み
	_, err = file.WriteString(`"id","name","email","email_verified_at","password","remember_token","created_at","updated_at"` + "\n")
	if err != nil {
		panic(err)
	}

	var user User
	for rows.Next() {
		err = rows.Scan(
			&user.ID,
			&user.Name,
			&user.Email,
			&user.EmailVerifiedAt,
			&user.Password,
			&user.RememberToken,
			&user.CreatedAt,
			&user.UpdatedAt,
		)
		if err != nil {
			panic(err)
		}

		line = fmt.Sprintf(
			`%d,"%s","%s","%s","%s","%s","%s","%s"`+"\n",
			user.ID,
			user.Name,
			user.Email,
			user.EmailVerifiedAt.Format("2006-01-02 15:04:05"),
			user.Password,
			user.RememberToken,
			user.CreatedAt.Format("2006-01-02 15:04:05"),
			user.UpdatedAt.Format("2006-01-02 15:04:05"))

		_, err = file.WriteString(line)
		if err != nil {
			panic(err)
		}
	}
	println(time.Now().Format("2006-01-02 15:04:05.000000") + " export CSV end")

	// 入力CSVと出力CSVを突合
	println(time.Now().Format("2006-01-02 15:04:05.000000") + " compare CSV start ")
	var (
		file1   *os.File
		file2   *os.File
		reader1 *csv.Reader
		reader2 *csv.Reader
		lines1  []string
		lines2  []string
		err1    error
		err2    error
	)

	file1, err1 = os.Open("../import_users.csv")
	if err1 != nil {
		panic(err1)
	}
	file2, err2 = os.Open("./export_users.csv")
	if err2 != nil {
		panic(err2)
	}
	defer file1.Close()
	defer file2.Close()

	reader1 = csv.NewReader(file1)
	reader2 = csv.NewReader(file2)
	for {
		lines1, err1 = reader1.Read()
		lines2, err2 = reader2.Read()
		if len(lines1) != len(lines2) {
			panic("入力CSVと出力CSVが一致しません")
		}
		if err1 != nil && err2 != nil {
			// 処理終了
			break
		}
		if !(lines1[0] == lines2[0] &&
			lines1[1] == lines2[1] &&
			lines1[2] == lines2[2] &&
			lines1[3] == lines2[3] &&
			lines1[4] == lines2[4] &&
			lines1[5] == lines2[5] &&
			lines1[6] == lines2[6] &&
			lines1[7] == lines2[7]) {
			panic("入力CSVと出力CSVが一致しません")
		}
	}
	println(time.Now().Format("2006-01-02 15:04:05.000000") + " compare CSV end ")
}

func main() {

	println("Go " + runtime.Version())

	times := []float64{}
	for i := 1; i <= 10; i++ {
		start := time.Now()
		startNanoTime := start.UnixNano()
		println(start.Format("2006-01-02 15:04:05.000000"))

		// 初期化
		initialize()

		// 負荷処理
		work()

		end := time.Now()
		endNanoTime := end.UnixNano()
		println(end.Format("2006-01-02 15:04:05.000000"))

		// 秒に変換
		s := float64(endNanoTime-startNanoTime) / float64(1000*1000*1000) // ミリ * マイクロ * ナノ
		println(fmt.Printf("%f", s))
		times = append(times, s)
	}
	var sum float64
	for _, s := range times {
		sum += s
	}
	avg := float64(sum / float64(len(times)))
	println(fmt.Printf("平均秒数：%f", avg))

}
