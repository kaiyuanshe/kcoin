KCoin Project
========

# Contribute
Pull request is welcome and appreciated. KCoin consists of two components, web and a backend rest server
to talk with Hyper Leger/Ethereum. For the backend, see [KCoin Server Guide](https://github.com/kaiyuanshe/kcoin/tree/master/src/server)
. Below are quick steps to setup dev environment for the web:

- Clone source code: `git clone https://github.com/kaiyuanshe/kcoin.git`
- Initialize project:
```
cd kcoin/src/web
bundle install
cp lib/config-sample.rb lib/config.rb
```
- Open config file `lib/config.rb` and update config values like github oauth secret.
   - github oauth setting: 
	![image](https://github.com/yiranblade/kcoin/blob/master/img/github_oauth.png)
   - config.rb setting:
```
CONFIG = {
  github: {
    client_id: '067295f33545d712270e',
    client_secret: '5b1877996ca6374955313d1b4915662d5606be39',
    sign_event: true
  },
  server: {
    url: 'http://localhost:8080'
  },
  email: {
    form: 'kcoin@kaiyuanshe.cn',
    address: 'smtp.exmail.qq.com',
    port: 587,
    helo: 'qq.com',
    user: 'kcoin@kaiyuanshe.cn',
    secret: '<Your email password here>',
    account: 'kcoin@kaiyuanshe.cn'
  }
}.freeze
```
```
When you apply for github oauth,you need to set callback url:
'http://localhost:9292/auth/github/callback'
If you forget it,plese delete 'src/web/kcoin.sqlite' and try again.
```
- Start the server: `puma -C config/puma_local.rb`
- browse [http://127.0.0.1:9292/](http://127.0.0.1:9292/)

# Documentation

KCoin is built on several popular ruby frameworks:
- [Sinatra](http://sinatrarb.com/documentation.html): web framework on top of rack.
- [Sqlite](https://www.sqlite.org/docs.html): database
- [sequel](https://sequel.jeremyevans.net/documentation.html): database toolkit for ruby
- [Haml](http://haml.info/docs/yardoc/): Html template engine ofr presentation layer
- [metroui](https://metroui.org.ua/intro.html): CSS library to build Metro-style UI.

# Author
[Kaiyuanshe](http://www.kaiyuanshe.cn)

# License

# Copyright
Copyright (c) Kaiyuanshe
