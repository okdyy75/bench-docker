<?php

/**
 * DB取得
 * 
 * @return PDO
 */
function getDB()
{
    $host = getenv('DB_HOST') ?: 'localhost';
    $port = getenv('DB_PORT') ?: '3306';
    $dbname = getenv('DB_NAME') ?: 'db';
    $user = getenv('DB_USER') ?: 'root';
    $password = getenv('DB_PASSWORD') ?: '';
    $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8";

    $db = new PDO(
        $dsn,
        $user,
        $password,
        [
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
        ]
    );
    return $db;
}

/**
 * 初期化
 *
 * @param PDO $db
 * @return void
 */
function initialize($db)
{
    $sql = <<<EOT
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
EOT;
    $db->query($sql);
    $db->query('TRUNCATE users;');
}

/**
 * CSV読み込み＆DBインサート＆CSV書き出し
 *
 * @param PDO $db
 * @return void
 */
function work($db)
{
    // CSV読み込み
    printTime('import CSV start');
    $handle = fopen('../import_users.csv', 'r');
    fgetcsv($handle); // ヘッダースキップ
    while (($row = fgetcsv($handle)) !== false) {
        $sql = <<<EOT
INSERT INTO users (
    name,
    email,
    email_verified_at,
    password,
    remember_token,
    created_at,
    updated_at
) values (
    :name,
    :email,
    :email_verified_at,
    :password,
    :remember_token,
    :created_at,
    :updated_at
);
EOT;
        $stmt = $db->prepare($sql);
        $stmt->bindValue(':name', $row[1]);
        $stmt->bindValue(':email', $row[2]);
        $stmt->bindValue(':email_verified_at', $row[3]);
        $stmt->bindValue(':password', $row[4]);
        $stmt->bindValue(':remember_token', $row[5]);
        $stmt->bindValue(':created_at', $row[6]);
        $stmt->bindValue(':updated_at', $row[7]);
        $stmt->execute();
    }
    fclose($handle);
    printTime('import CSV end');

    $stmt = $db->query('select * from users order by id');
    $stmt->execute();
    $users = $stmt->fetchall();

    // CSV書き出し ※fputcsvは一部ダブルクォーテーションで囲まれたり囲まれなかったりするので使わない
    printTime('export CSV start');
    $fp = fopen('./export_users.csv', 'w');
    fwrite($fp, '"id","name","email","email_verified_at","password","remember_token","created_at","updated_at"' . "\n");
    foreach ($users as $user) {
        // 数値以外はダブルクォーテーションで囲む
        $user = array_map(function ($item) {
            return is_numeric($item) ? $item : '"' . $item . '"';
        }, $user);
        fwrite($fp, implode(',', [
            $user['id'],
            $user['name'],
            $user['email'],
            $user['email_verified_at'],
            $user['password'],
            $user['remember_token'],
            $user['created_at'],
            $user['updated_at'],
        ]) . PHP_EOL);
    }
    fclose($fp);
    printTime('export CSV end');

    // 入力CSVと出力CSVを突合
    printTime('compare CSV start');
    $handle1 = fopen('../import_users.csv', 'r');
    $handle2 = fopen('./export_users.csv', 'r');
    while (true) {
        $row1 = fgetcsv($handle1);
        $row2 = fgetcsv($handle2);
        if ($row1 === false && $row2 === false) {
            // 処理終了
            break;
        }
        if (!($row1[0] === $row2[0]
            && $row1[1] === $row2[1]
            && $row1[2] === $row2[2]
            && $row1[3] === $row2[3]
            && $row1[4] === $row2[4]
            && $row1[5] === $row2[5]
            && $row1[6] === $row2[6]
            && $row1[7] === $row2[7])) {
            throw new Exception('入力CSVと出力CSVが一致しません');
        }
    }
    fclose($handle1);
    fclose($handle2);
    printTime('compare CSV end');
}

/**
 * 実行時間を出力
 *
 * @param string $message
 * @return void
 */
function printTime($message)
{
    echo DateTime::createFromFormat('U.u', microtime(true))->format('Y-m-d H:i:s.u') . ' ' . $message . PHP_EOL;
}

/**
 * メイン処理
 * 
 * @return void
 */
function main()
{
    echo 'PHP ' . phpversion() . PHP_EOL;

    $db = getDB();

    $times = [];
    for ($i = 1; $i <= 10; $i++) {
        $startMicroTime = microtime(true);
        $start = DateTime::createFromFormat('U.u', $startMicroTime);
        echo $start->format('Y-m-d H:i:s.u') . PHP_EOL;

        // 初期化
        initialize($db);

        // 負荷処理
        work($db);

        $endMicroTime = microtime(true);
        $end = DateTime::createFromFormat('U.u', $endMicroTime);
        echo $end->format('Y-m-d H:i:s.u') . PHP_EOL;

        // 秒数
        $s = ($endMicroTime - $startMicroTime);
        echo $s . PHP_EOL;

        $times[] = $s;
    }
    $avg = array_sum($times) / count($times);
    echo '平均秒数：' . $avg . PHP_EOL;
}

// メイン処理
main();
