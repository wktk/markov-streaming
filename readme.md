```shell
git clone https://github.com/wktk/markov-streaming.git
cd markov-streaming
heroku create
git push heroku master
heroku config:add APPID=hoge CONSUMER_KEY=hoge CONSUMER_SECRET=hoge
heroku config:add ACCESS_TOKEN=hoge ACCESS_TOKEN_SECRET=hoge
```
