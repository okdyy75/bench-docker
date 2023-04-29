<?php

// オプション参考
// https://dev.mysql.com/doc/refman/5.6/ja/server-system-variables.html 
const MYSQL_OPTIONS = [
    'default_storage_engine' => [
        'InnoDB',
        'MyISAM', /* トランザクションが使えない */
        'ARCHIVE', /* SELECT,INSERTのみ。UNIQUEが使えない */
        'MEMORY', /* max_heap_table_size=1844674407370954752, tmp_table_size=18446744073709551615  */
        // 'CSV', /* auto_incrementが使えない。PKを使えない。NULL許可カラムが作れない。 */
        // 'PERFORMANCE_SCHEMA', /* パフォーマンス計測に使用する */
        // 'MRG_MYISAM', /* 複数のテーブルを結合し、あたかも1つのテーブルで処理しているかのようにできる */
        // 'BLACKHOLE', /* マスター/スレーブ構成の時に使う */
        // 'FEDERATED', /* 簡易的なマスター/スレーブ構成を作れる */
    ],
    // 'connect_timeout' => ['2', '10', '31536000'],
    // 'concurrent_insert' => ['NEVER', 'AUTO', 'ALWAYS'],
    // 'completion_type' => ['NO_CHAIN', 'CHAIN', 'RELEASE'],
    // 'bulk_insert_buffer_size' => ['0', '8388608', '18446744073709551615'],
    // 'big_tables'      => ['ON', 'OFF'],
    // 'back_log'      => ['1', '65535'],
    // 'autocommit'    => ['ON', 'OFF'],
    // 'innodb_flush_log_at_trx_commit' => ['0', '1', '2'],
    // 'innodb_doublewrite' => ['ON', 'OFF'],
    // 'innodb_flush_method' => ['fsync', 'O_DIRECT', 'O_DIRECT_NO_FSYNC'],
    // 'innodb_adaptive_hash_index' => ['ON', 'OFF']
];


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
 * ワーク
 *
 * @return void
 */
function work()
{
    printTime('work start');

    $result = [];
    foreach (MYSQL_OPTIONS as $option => $values) {
        foreach ($values as $value) {
            // mysqlオプション設定＆再起動
            $cnf = <<<EOT
[mysqld]
character-set-server=utf8
{$option}={$value}

# ストレージエンジンでMEMORYを使う場合に必要
max_heap_table_size=1844674407370954752
tmp_table_size=18446744073709551615
EOT;
            file_put_contents('/etc/my.cnf', $cnf);
            exec('systemctl restart mysqld.service');

            // 変更後のmysqlオプション確認
            $db = getDB();
            $variable = $db->query("show variables like '{$option}';")->fetch();
            var_dump($variable);
            if ($option !== $variable['Variable_name'] || $value !== $variable['Value']) {
                throw new Exception('MySQLオプションの変更に失敗しています。');
            }

            // ベンチ計測
            $output = null;
            $retval = null;
            exec('time -p php ./bench.php 2>&1', $output, $retval);
            var_dump($output);
            $sysTime = (float) explode(' ', end($output))[1];
            $usrTime = (float) explode(' ', prev($output))[1];
            $realTime = (float) explode(' ', prev($output))[1];
            $idleTime = $realTime - ($usrTime + $sysTime);
            $r = [
                'option'    => $option,
                'value'     => $value,
                'real_time' => $realTime,
                'usr_time'  => $usrTime,
                'sys_time'  => $sysTime,
                'idle_time'  => $idleTime,
            ];
            $result[] = $r;
            var_dump($r);
        }
    }

    // 待機時間が短い順にソート
    $sort = [];
    foreach ($result as $key => $val) {
        $sort[$key] = $val['idle_time'];
    }
    array_multisort($sort, SORT_ASC, $result);

    // tsv形式で出力
    $handle = fopen('./result.tsv', 'w');
    fputcsv($handle, ['option', 'value', 'real_time', 'usr_time', 'sys_time', 'idle_time'], "\t");
    foreach ($result as $r) {
        fputcsv($handle, [
            $r['option'],
            $r['value'],
            $r['real_time'],
            $r['usr_time'],
            $r['sys_time'],
            $r['idle_time'],
        ], "\t");
    }
    fclose($handle);

    printTime('work end');
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
    $db = getDB();

    work($db);
}

// メイン処理
main();
