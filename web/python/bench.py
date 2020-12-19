import csv
import os
import sys
from itertools import zip_longest
from datetime import datetime
import MySQLdb.cursors

config = {
    'db_host': os.environ.get('DB_HOST', 'localhost'),
    'db_port': int(os.environ.get('DB_PORT', '3306')),
    'db_name': os.environ.get('DB_NAME', 'db'),
    'db_user': os.environ.get('DB_USER', 'root'),
    'db_password': os.environ.get('DB_PASSWORD', ''),
}


def get_db():
    """DB取得
    :rtype: MySQLdb.Connection
    """

    db = MySQLdb.connect(
        host=config['db_host'],
        port=config['db_port'],
        user=config['db_user'],
        passwd=config['db_password'],
        db=config['db_name'],
        charset='utf8',
        cursorclass=MySQLdb.cursors.DictCursor,
        autocommit=True,
    )
    return db


def initialize(db):
    """初期化
    :param db: MySQLdb.Connection
    :rtype: None
    """

    cur = db.cursor()
    cur.execute('''
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
    ''')
    cur.execute('TRUNCATE users;')


def work(db):
    """CSV読み込み＆DBインサート＆CSV書き出し
    :param db: MySQLdb.Connection
    :rtype: None
    """

    # CSV読み込み
    print_time('import CSV start')
    with open('../import_users.csv') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            cur = db.cursor()
            cur.execute('''
                INSERT INTO users (
                    name,
                    email,
                    email_verified_at,
                    password,
                    remember_token,
                    created_at,
                    updated_at
                ) values (
                    %(name)s,
                    %(email)s,
                    %(email_verified_at)s,
                    %(password)s,
                    %(remember_token)s,
                    %(created_at)s,
                    %(updated_at)s
                );
            ''', {
                'name': row[1],  # row[0]はidのため1から
                'email': row[2],
                'email_verified_at': row[3],
                'password': row[4],
                'remember_token': row[5],
                'created_at': row[6],
                'updated_at': row[7]
            })
    print_time('import CSV end')

    cur = db.cursor()
    cur.execute('select * from users order by id')
    users = cur.fetchall()

    # CSV書き出し
    print_time('export CSV start')
    with open('./export_users.csv', 'w') as f:
        writer = csv.writer(f, delimiter=',', quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
        writer.writerow(['id', 'name', 'email', 'email_verified_at', 'password', 'remember_token', 'created_at', 'updated_at'])
        for user in users:
            writer.writerow([
                user['id'],
                user['name'],
                user['email'],
                user['email_verified_at'],
                user['password'],
                user['remember_token'],
                user['created_at'],
                user['updated_at']
            ])
    print_time('export CSV end')

    # 入力CSVと出力CSVを突合
    print_time('compare CSV start')
    f1 = open('../import_users.csv')
    f2 = open('./export_users.csv')
    reader1 = csv.reader(f1)
    reader2 = csv.reader(f2)
    for row1, row2 in zip_longest(reader1, reader2):
        if not (
            row1[0] == row2[0]
            and row1[1] == row2[1]
            and row1[2] == row2[2]
            and row1[3] == row2[3]
            and row1[4] == row2[4]
            and row1[5] == row2[5]
            and row1[6] == row2[6]
            and row1[7] == row2[7]
        ):
            raise Exception('入力CSVと出力CSVが一致しません')
    print_time('compare CSV end')


def print_time(message):
    """メイン処理
    :param message string:
    :type message: int
    :rtype: None
    """
    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f") + ' ' + message)

def main():
    """メイン処理
    :rtype: None
    """

    print('Python ' + sys.version)

    db = get_db()

    times = []
    for i in range(10):
        start = datetime.now().timestamp()

        print(datetime.fromtimestamp(start).strftime("%Y-%m-%d %H:%M:%S.%f"))

        # 初期化
        initialize(db)

        # 負荷処理
        work(db)

        end = datetime.now().timestamp()
        print(datetime.fromtimestamp(end).strftime("%Y-%m-%d %H:%M:%S.%f"))

        s = end - start
        print('%f' % s)

        times.append(s)

    svg = sum(times) / len(times)
    print('平均秒数：%f' % svg)


if __name__ == '__main__':
    # メイン
    main()
