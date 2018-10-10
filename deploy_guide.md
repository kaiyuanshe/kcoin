Instructions to deploy KCoin on CentOS 7/Ubuntu 16.04(verified on Huawei cloud).

# Prerequisites

### Install Nginx

#### CentOS
Config yum repo for Nginx by adding file `/etc/yum.repos.d/nginx.repo` with content:
```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
```
And then reset cache and install:
```
yum clean all
yum makecache
yum install nginx -y
```

#### Ubuntu
```
sudo apt-get update
sudo apt-get install nginx
```
You can change default port `/etc/nginx/sites-available/default`. But it's not required since we will override the `nginx.conf` later.

### Install Ruby(rvm recommended)

```
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -L get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install 2.4.0
rvm list
```
Run `ruby -version` to make sure it's ready

### Install bundler
```
gem install bundler
```

# Deploy KCoin
### source code
install git first if it's not ready by 
```
# CentOS
yum install git -y
yum update nss curl`

# Ubuntu
apt-get install git
```
run `yum update nss curl` if you met "Peer reports incompatible or unsupported protocol version" while pulling the source codes.
That's because the version of nss/curl is too old.

Then clone source code:
```
mkdir /var/www
mkdir /var/log/kcoin
cd /var/www
git clone https://github.com/kaiyuanshe/kcoin.git
```

### Start KCoin Web
```
cd /var/www/kcoin/src/web
bundle install
cp lib/config-sample.rb lib/config.rb # update config file if needed
puma -C config/puma.rb -d
```
Run `pumactl -P /var/run/puma.pid stop` to stop puma. And run `puma -C config/puma_prod.rb -d` again to start it.

### Config Nginx
```
cd /var/www/kcoin/src/web
cp config/nginx.conf /etc/nginx/nginx.conf # Ubuntu: update user to www-data by `user www-data;`, port to 8088
service nginx start  # centos
systemctl restart nginx.service # ubuntu
```
