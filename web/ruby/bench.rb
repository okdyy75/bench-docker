require "mysql2"
require "csv"

# DB取得
# @return [Mysql2::Client] db_client
def get_db
  db_client = Mysql2::Client.new(
    host: ENV.fetch("DB_HOST") { "localhost" },
    port: ENV.fetch("DB_PORT") { "3306" },
    username: ENV.fetch("DB_USER") { "root" },
    password: ENV.fetch("DB_PASSWORD") { "" },
    database: ENV.fetch("DB_NAME") { "db" },
    encoding: "utf8",
  )
  db_client
end

# 初期化
# @param [Mysql2::Client] db
def init(db)
  db.query(<<~EOS)
    CREATE TABLE IF NOT EXISTS `users` (
      `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
      `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
      `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
      `email_verified_at` timestamp NULL DEFAULT NULL,
      `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
      `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
      `created_at` timestamp NULL DEFAULT NULL,
      `updated_at` timestamp NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `users_email_unique` (`email`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  EOS

  db.query("TRUNCATE users;")
  # p db.query("select count(*) as cnt from users;").to_a
end

# CSV読み込み＆DBインサート＆CSV書き出し
# @param [Mysql2::Client] db
def work(db)

  # CSV読み込み
  print_time("import CSV start")
  CSV.foreach("../import_users.csv", headers: true) do |row|
    statement = db.prepare(<<~EOS)
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
    EOS
    # row[0]はidのため1から
    statement.execute(row[1], row[2], row[3], row[4], row[5], row[6], row[7])
  end
  print_time("import CSV end")

  users = db.query("select * from users order by id")

  # CSV書き出し
  print_time("export CSV start")
  file = File.open("./export_users.csv", "w")
  file.write('"id","name","email","email_verified_at","password","remember_token","created_at","updated_at"' << "\n")
  users.each do |row|
    user = row.map do |k, v|
      v = v.strftime("%Y-%m-%d %H:%M:%S") if v.is_a?(Time)
      v = %Q{"#{v}"} if !v.is_a?(Integer)
      v
    end
    file.write(user.join(",") << "\n")
  end
  file.close
  print_time("export CSV end")

  # 入力CSVと出力CSVを突合
  print_time("compare CSV start")
  file1 = File.open("../import_users.csv", "r")
  file2 = File.open("./export_users.csv", "r")
  while true
    line1 = file1.gets
    line2 = file2.gets
    if line1.nil? && line2.nil?
      # 処理終了
      break
    end

    row1 = CSV.parse_line(line1)
    row2 = CSV.parse_line(line2)
    if !(row1[1] == row2[1] &&
         row1[2] == row2[2] &&
         row1[3] == row2[3] &&
         row1[4] == row2[4] &&
         row1[5] == row2[5] &&
         row1[6] == row2[6] &&
         row1[7] == row2[7])
      raise("入力CSVと出力CSVが一致しません")
    end
  end
  file1.close
  file2.close
  print_time("compare CSV end")
end

# 実行時間を出力
# @param [String]
def print_time(message)
  p Time.now.strftime("%Y-%m-%d %H:%M:%S.%6N") << " " << message
end

# メイン処理
def main
  p "Ruby " << RUBY_VERSION

  db = get_db

    start_time = Time.now
  p start_time.strftime("%Y-%m-%d %H:%M:%S.%6N") << " main start"

    # 初期化
    init(db)

    # 負荷処理
    work(db)

    end_time = Time.now
  p end_time.strftime("%Y-%m-%d %H:%M:%S.%6N") << " main end"

  # 秒数
    s = end_time - start_time
  p sprintf("実行秒数：%.6f", s)
  end

# メイン処理
main
