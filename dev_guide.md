KCoin Project

# Contribute
Pull request is welcome and appreciated.

## Pull Request
To contribute source codes to KCoin, basically you need to:

- Fork `kaiyuanshe/kcoin` project to your personal account
- Clone source code: `git clone https://github.com/<your github account>/kcoin.git`
- Make changes, make sure it's well tested
- Commit and push changes to your own repo
- Send out pull request which should include clear title, a detailed description about your changes and what tests you have done
- [TODO]A CI task will be added soon to make sure your changes compile
- Your PR will be reviewed soon. 
- Resolve review comments and submit updates if changes are requested
- Your PR will be merged after all comments are resolved

KCoin consists of two components, a standard ruby web server and a java-based backend server as a proxy to forward blockchain requests to HyperLeger. See below for details.

## Web(Ruby)

Below are quick steps to setup dev environment for the web:

- Install Ruby if you haven't and `rvm` is recommended.

```
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -L get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install 2.4.0
rvm list
```
Run `ruby -version` to make sure it's ready

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
    client_id: 'xxxxxxxxxxxxx',
    client_secret: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    sign_event: true
  },
  server: {
    url: 'http://localhost:8080'
  },
  email: {
    form: 'notification@kaiyuanshe.org',
    address: 'smtp.exmail.qq.com',
    port: 587,
    helo: 'qq.com',
    user: 'notification@kaiyuanshe.org',
    secret: '<Your email password here>',
    account: 'notification@kaiyuanshe.org'
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
- For quick test: `puma -C config/puma_local.rb` and browse [http://localhost:9292/](http://localhost:9292/)

### IDE

Install RubyMine or VS Code, or any other preferred IDE first. Open `<repo>\src\web`.
To start/debug in RubyMime, add a new Rack configuration with default parameters.

### Conventions

- file `lib/config-sample.rb` is just a sample. Changing values in this file makes no difference to your running app. You need to copy the contents to `lib/config.rb` and update config values to adapt your local environment. In case you add any new config item, add to the sample file first. Don't push `lib/config.rb` to github. It's ignored by default.
- Don't push any confidentials to github like oauth key/secret and HyperLedger certificates.
- In case any database schema changes, add new migration file in directory `config/migrations`. Never alter table schema directly in existing migration files. That's because migration of the same name only gets executed once. 
- While requesting HyperLedger, user `invoke` API if you need to write any data into blockchain,  or `query` API if read data only. See `src/web/helpers/fabric_helpers.rb` for example. 

### Components
KCoin is built on several popular ruby frameworks:
- [Sinatra](http://sinatrarb.com/documentation.html): web framework on top of rack.
- [Sqlite](https://www.sqlite.org/docs.html): database
- [sequel](https://sequel.jeremyevans.net/documentation.html): database toolkit for ruby
- [Haml](http://haml.info/docs/yardoc/): Html template engine for presentation layer
- [metroui](https://metroui.org.ua/intro.html): CSS library to build Metro-style UI.
You don't need to install them one by one manually. All required tools/gems are included in Gemfile.

### Database

KCoin uses HyperLedger to persist token and token history. At the same time uses sqlite to store user profile, github project metadata and so on. Data in sqlite can be edited and deleted. But data in HyperLedger cannot be revoked or deleted.

In your local dev environment, you can download **DB Browser for SQLite** or CLI tool `sqlite3` to view (and edit) your local data. 

## Server

The JFinal-based backend server is only a proxy for HyperLedger because HyperLedger doesn't have a Ruby SDK. In most cases, you only want to run the server without changing any Java source codes. But if you want learn about the details, about the hierarchy of backend server, see [KCoin Server Guide](https://github.com/kaiyuanshe/kcoin/tree/master/src/server)

### prerequisite
- JDK8
- Maven(mvn3 is recommended)

### To run the server

- Firstly you need to get HyperLedger client certificates, contact dev team for the certificates. Create an issue on Github if needed. 
- Unzip and place the certificates to `<repo>/src/server/src/main/resources/fabric`. **Never push the certificates to github in any form**
- Resolve HyperLedger dns locally by adding following records to `/etc/hosts`(Linux) or `C:\Windows\System32\drivers\etc\hosts`(Windows). Note that the IP `117.78.50.99` and DNS might change in future when time goes by. Update hosts file if needed. See `<repo>/src/server/src/main/resources/config.properties` for the latest IP address, and `kcoin-sdk-config-dev.yaml` for latest DNS(usually part of `url` config).

```
117.78.48.87 orderer-81efaa2f8ec402ad2c8743d99c0609550d4ca2f0-0.orderer-81efaa2f8ec402ad2c8743d99c0609550d4ca2f0.default.svc.cluster.local
117.78.48.87 peer-51809cd89ab98256de47e9908c70c588a8e4db01-0.peer-51809cd89ab98256de47e9908c70c588a8e4db01.default.svc.cluster.local
```
- Run `mvn jetty:run` in command line. Or run Maven task in inteliJ IDEA or Eclipse.
- Test HyperLedger: `curl -vvv -H "Content-Type:application/json"  -X POST --data '{"fn":"balance", "args":["symbol","owner"]}' http://localhost:8080/fabric/query`. If responded http status code is 200, it's working and running as expected. Otherwise you may need to debug in IDE or call for dev team for help.
- [Optional]Instead of issue `curl ...` in commandline, you can download API test tool such as PostMan for easier testing

### chaincode development

Chaincode is one of key concepts in HyperLedger which is written in GO language. See https://hyperledger-fabric.readthedocs.io/en/release-1.2/chaincode4ade.html for more.

KCoin deploys chaincode to Huawei BCS. The process of develop and deploy chaincode:
- You can find the lastest KCoin chaincode in `<repo>/src/server/src/resources/chaincode/kctoken.go`
- Setup your local environment following KCoin chaincode dev guide: `<repo>/src/server/chaincode.MD` which also includes how to guide about how to test chaincode locally
- Make changes to `kctoken.go` and **have it well tested** in your local environment.
- Submit changes to the main repo via PR
- After PR merged, Dev team will upload the lasted chaincode to Huawei cloud and update chaincode version in `<repo>/src/server/src/main/resources/config.properties`

## Things to know

Some other things to be aware of:
- Never use tab charactor in source code no matter language/IDE. Use spaces instead. Please update your IDE settings, to replace tab with 4 spaces for Java/GO code, 2 spaces in Ruby/JavaScript code
- Follow common best practices for programming: https://practicingruby.com/
- TBD

# Author
[Kaiyuanshe](http://www.kaiyuanshe.cn)

# License
MIT

# Copyright
Copyright (c) Kaiyuanshe
