# bench
各言語のベンチマーク計測

### 計測方法
1. 1万行のCSVを読み込んでDBに登録
3. 登録したDBのデータをCSVに吐き出す
4. 入力CSVと出力CSVを突合して確認
5. 計10回実行してその平均を出す

記事公開時のソースはタグv1を参照してください。  
https://qiita.com/okdyy75/items/c6f1469ed6a74a075151  

## サーバースペック
できるだけ汎用的な環境で計測  
https://aws.amazon.com/jp/ec2/instance-types/

| インスタンスサイズ | vCPU | メモリ (GiB) | インスタンスストレージ(GiB)  | ネットワーク帯域幅 (Gbps) | EBS 帯域幅 (Mbps) |
|-----------------|------|-------------|--------------------------|------------------------|------------------|
| m5d.large       |  2   |    8        | 1 x 75 NVMe SSD          | 最大 10                 | 最大 4,750       |

- Amazon Linux 2 AMI (HVM), SSD Volume Type - ami-00f045aed21a55240 (64 ビット x86)


ローカルで動作確認
```
docker-compose run --rm golang sh -c 'sh bench.sh --lang=go --count=10'
docker-compose run --rm php-fpm sh -c 'sh bench.sh --lang=php --count=10'
docker-compose run --rm python sh -c 'sh bench.sh --lang=python --count=10'
docker-compose run --rm ruby sh -c 'sh bench.sh --lang=ruby --count=10'
```
