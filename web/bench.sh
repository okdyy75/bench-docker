#!/bin/bash

# ヘルプ表示
function help() {
cat <<EOT
Usage:
  $0 [--lang=(go|php|python|ruby)] --count=10(defalut)

Description:
  start bench

Options:
  --lang    target language
  --count   bench count

EOT
}

LANG_FLG=0
COUNT_VAL=10

# オプション引数受け取り
while getopts :-: opt; do

  # OPTARG を = の位置で分割して opt と optarg に代入
  optarg="$OPTARG"
  [[ "$opt" = - ]] &&
    opt="-${OPTARG%%=*}" &&
    optarg="${OPTARG/${OPTARG%%=*}/}" &&
    optarg="${optarg#=}"

  case "-$opt" in
    --lang)
      LANG_FLG=1
      LANG_VAL="$optarg"
      ;;
    --count)
      COUNT_VAL="$optarg"
      ;;
    -h|--help)
      help
      exit 0
      ;;
  esac
done

# ベンチ計測
if [ "$LANG_FLG" = 1 ]; then
  COMMAND=""
  case "$LANG_VAL" in
    go)
      cd /var/www/web/go
      go build .
      COMMAND="cd /var/www/web/go; time -f 'real %e user %U sys %S' -a -o /tmp/mtime.$$ ./go"
      ;;
    python)
      cd /var/www/web/python
      pip install -r ./requirements.txt
      COMMAND="cd /var/www/web/python; time -f 'real %e user %U sys %S' -a -o /tmp/mtime.$$ python bench.py"
      ;;
    python3)
      cd /var/www/web/python
      pip3 install -r ./requirements.txt
      COMMAND="cd /var/www/web/python; time -f 'real %e user %U sys %S' -a -o /tmp/mtime.$$ python3 bench.py"
      ;;
    php)
      COMMAND="cd /var/www/web/php; time -f 'real %e user %U sys %S' -a -o /tmp/mtime.$$ php bench.php"
      ;;
    ruby)
      cd /var/www/web/ruby
      bundle install --path vendor/bundle
      COMMAND="cd /var/www/web/ruby; time -f 'real %e user %U sys %S' -a -o /tmp/mtime.$$ bundle exec ruby bench.rb"
      ;;
    *)
      echo "language not found."
      exit 0
      ;;
  esac
  for i in `seq 1 $COUNT_VAL`; do
    eval ${COMMAND}
  done

  # 実行結果を集計＆表示
  awk '
    { et += $2; ut += $4; st += $6; count++ }
    END {
      printf "Count:\n%d\n", count
      printf "Sum:\nreal %.3f user %.3f sys %.3f\n", et, ut, st
      printf "Average:\nreal %.3f user %.3f sys %.3f\n", et/count, ut/count, st/count
    }
  ' /tmp/mtime.$$
  rm /tmp/mtime.$$

else
  echo "See --help option."
fi

exit 0
