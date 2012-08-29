markov-streaming
==========

Twitter のストリーミング API で受信したツイートを単語ごとに分割したものから
マルコフ連鎖で文章を生成し、リプライで送信する bot です。

markov-streaming は単語分割を行うために、オリジナルからコンパイルした
[NAIST Japanese Dictionary](http://sourceforge.jp/projects/naist-jdic/)
(mecab-naist-jdic-0.6.3b-20111013) を含んでいます。
この辞書の著作権・ライセンスについて naist-jdic/COPYING を御覧ください。


## 利用方法

### [Heroku](http://www.heroku.com/) への設置方法

(要 [heroku-toolbelt](http://toolbelt.heroku.com/))
``` sh
git clone https://github.com/wktk/markov-streaming.git
cd markov-streaming
heroku create
git push heroku master
heroku config:add CONSUMER_KEY=hoge CONSUMER_SECRET=hoge ACCESS_TOKEN=hoge ACCESS_TOKEN_SECRET=hoge
heroku ps:scale worker=1
```
プロセスを停止する場合は `heroku ps:scale worker=0` を実行してください。

### 通常のサーバーで動かす場合
ruby から main.rb を実行してください。
アクセストークンは環境変数に設定するか、main.rb 内に直接記述してください。

