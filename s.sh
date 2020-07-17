#!/bin/bash
INSTALLSH_VERSION=1.0.10
cd ~
wget https://github.com/yeqing112/webSiteConfig/archive/${INSTALLSH_VERSION}.tar.gz \
&& tar -zxvf ${INSTALLSH_VERSION}.tar.gz
mkdir /data
cd /data
cp -r ~/webSiteConfig-${INSTALLSH_VERSION}/* /data
# 创建容器网络
docker network create myproxy
# 启动数据库
docker run -dit --name mysql57 \
	-e MYSQL_ROOT_PASSWORD=123456 \
	-p 3306:3306 \
	-v $PWD/data:/var/lib/mysql \
	--network=myproxy \
	--restart=always \
	registry.cn-shanghai.aliyuncs.com/yeqing112/mysql:5.7
# 启动php7.2环境
docker run -dit --name php_fpm \
	-v $PWD/www:/data/www \
	-v $PWD/php7/php-fpm.d/www.conf:/etc/php7/php-fpm.d/www.conf \
	-v $PWD/php7/php-fpm.conf:/etc/php7/php-fpm.conf \
	-v $PWD/php7/php.ini:/etc/php7/php.ini \
	--network=myproxy \
	--restart=always \
	registry.cn-shanghai.aliyuncs.com/yeqing112/php:7.3-fpm-alpine
# 启动nginx
docker run -dit --name nginx \
	-p 80:80 -p 443:443 \
	-v $PWD/www:/data/www \
	-v $PWD/nginx/nginx.conf:/etc/nginx/nginx.conf \
	-v $PWD/nginx/conf.d:/etc/nginx/conf.d \
	-v $PWD/nginx/fastcgi.conf:/etc/nginx/fastcgi.conf \
	-v $PWD/nginx/rewrite.conf:/etc/nginx/rewrite.conf \
	-v $PWD/ssl:/etc/nginx/ssl \
	--network=myproxy \
	--restart=always \
	registry.cn-shanghai.aliyuncs.com/yeqing112/nginx:1.19.1
# phpmyadmin
docker run -d --name myadmin \
	--link mysql57:db \
	-p 8080:80 \
	--network=myproxy \
	registry.cn-shanghai.aliyuncs.com/yeqing112/phpmyadmin:latest
