#!/bin/bash
cd ~
mkdir mysite && cd mysite
wget https://github.com/yeqing112/webSiteConfig/archive/1.0.2.tar.gz \
&& tar -zxvf 1.0.2.tar.gz \
&& cd webSiteConfig-1.0.2
mkdir data
# 创建容器网络
docker network create myproxy
# 启动数据库
docker run -d --name mysql57 -e MYSQL_ROOT_PASSWORD=3165ilcy -p 3306:3306 -v $PWD/data:/var/lib/mysql --network=myproxy --restart=always registry.cn-shanghai.aliyuncs.com/yeqing112/mysql:5.7
# 启动php7.2环境
docker run -d --name php_fpm -v $PWD/www:/data/www --network=myproxy --restart=always registry.cn-shanghai.aliyuncs.com/yeqing112/php:7.3-fpm-alpine
# 启动nginx
docker run -d --name nginx -p 80:80 -p 443:443 -v $PWD/www:/data/www -v $PWD/nginx/conf.d:/etc/nginx/conf.d -v $PWD/nginx/fastcgi.conf:/etc/nginx/fastcgi.conf -v $PWD/nginx/rewrite.conf:/etc/nginx/rewrite.conf -v $PWD/ssl:/etc/nginx/ssl --network=myproxy --restart=always registry.cn-shanghai.aliyuncs.com/yeqing112/nginx:1.19.1
