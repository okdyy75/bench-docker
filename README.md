# bench
各言語のベンチマーク計測

### 計測方法
1. 1万行のCSVを読み込んでDBに登録
3. 登録したDBのデータをCSVに吐き出す
4. 入力CSVと出力CSVを突合して確認
5. 計10回実行してその平均を出す

記事公開時のソースはタグv1を参照してください。  
https://qiita.com/okdyy75/items/c6f1469ed6a74a075151  

ローカルで動作確認
```
docker-compose run --rm golang sh -c 'sh bench.sh --lang=go --count=10'
docker-compose run --rm php-fpm sh -c 'sh bench.sh --lang=php --count=10'
docker-compose run --rm python sh -c 'sh bench.sh --lang=python --count=10'
docker-compose run --rm ruby sh -c 'sh bench.sh --lang=ruby --count=10'
```
