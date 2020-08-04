#!/bin/bash
INSTALLSH_VERSION=1.0.18
ssl="off"
inputData(){
	# 域名
	echo -e "请输入域名，多个域名请用空格分隔: \c"
	read domain
	if  [ ! -n "$domain" ] ; then
	echo "域名不能为空!"
	exit
	fi
	
	# 端口
	echo -e "请输入端口，多个端口请用空格分隔: \c"
	read port
	if  [ ! -n "$port" ] ; then
	echo "域名不能为空!"
	exit
	fi
	
	# php版本
	echo -e "请选择PHP版本（1.php5.6 | 2.php7.2 ），填写相应数字：\c"
	read phpVersion
	if  [ ! -n "$phpVersion" ] ; then
	echo "PHP版本不能为空!"
	exit
	fi	

	# 数据库名称
	echo -e "请输入数据库名称: \c"
	read dbname
	if  [ ! -n "$dbname" ] ; then
	echo "数据库名称不能为空!"
	exit
	fi	

	# 数据库密码
	echo -e "请输入数据库密码: \c"
	read password
	if  [ ! -n "$password" ] ; then
	echo "密码不能为空!"
	exit
	fi
}

downloadConfig(){
	cd ~
	wget https://github.com/yeqing112/webSiteConfig/archive/${INSTALLSH_VERSION}.tar.gz \
	&& tar -zxvf ${INSTALLSH_VERSION}.tar.gz
	mkdir /data
	cd /data
	cp -r ~/webSiteConfig-${INSTALLSH_VERSION}/* /data
}

setupWebsite(){
	# 设置域名
	sed -i "s/{w:domain:w}/\tserver_name  $domain;/g" /data/nginx/conf.d/default.conf
	
	# 设置端口
	strPort=""
	for str in ${port[@]};do
		if [ $str == 443 ]; then
			strPort=$strPort"\tlisten  $str ssl;\n"
			ssl="on"
		else
			strPort=$strPort"\tlisten  $str;\n"
		fi
	done
	sed -i "s/{w:port:w}/$strPort/g" /data/nginx/conf.d/default.conf
	
	# 如果有443端口，则配置证书
	if [ $ssl == "on" ]; then
		sed -i "s/{w:certificate:w}/\tinclude ssl.conf;/g" /data/nginx/conf.d/default.conf
	else
		sed -i "s/{w:certificate:w}//g" /data/nginx/conf.d/default.conf
	fi
	
	# 写入数据库相关配置
	sed -i "s/{w:dbname:w}/$dbname/g" /data/db.sh
	sed -i "s/{w:password:w}/$password/g" /data/db.sh
}

php5(){
	docker run -dit --name php_fpm \
		-v $PWD/www:/data/www \
		-v $PWD/php5/php-fpm.conf:/etc/php5/php-fpm.conf \
		-v $PWD/php5/php.ini:/etc/php5/php.ini \
		--network=myproxy \
		--restart=always \
		registry.cn-shanghai.aliyuncs.com/yeqing112/php:5.6-fpm-alpine
}

php7(){
	docker run -dit --name php_fpm \
		-v $PWD/www:/data/www \
		-v $PWD/php7/php-fpm.d/www.conf:/etc/php7/php-fpm.d/www.conf \
		-v $PWD/php7/php-fpm.conf:/etc/php7/php-fpm.conf \
		-v $PWD/php7/php.ini:/etc/php7/php.ini \
		--network=myproxy \
		--restart=always \
		registry.cn-shanghai.aliyuncs.com/yeqing112/php:7.3-fpm-alpine
}

dockerRun(){
	# 创建容器网络
	docker network create myproxy
	# 启动数据库
	docker run -dit --name mysql57 \
		-e MYSQL_ROOT_PASSWORD=$password \
		-p 3306:3306 \
		-v $PWD/data:/var/lib/mysql \
		--network=myproxy \
		--restart=always \
		registry.cn-shanghai.aliyuncs.com/yeqing112/mysql:5.7
	# 启动php环境
	if [ $phpVersion == "1" ]; then
		php5
	else
		php7
	fi
	# 启动nginx
	docker run -dit --name nginx \
		-p 80:80 -p 443:443 \
		-v $PWD/www:/data/www \
		-v $PWD/nginx/nginx.conf:/etc/nginx/nginx.conf \
		-v $PWD/nginx/conf.d:/etc/nginx/conf.d \
		-v $PWD/nginx/fastcgi.conf:/etc/nginx/fastcgi.conf \
		-v $PWD/nginx/rewrite.conf:/etc/nginx/rewrite.conf \
		-v $PWD/nginx/ssl.conf:/etc/nginx/ssl.conf \
		-v $PWD/nginx/ssl:/etc/nginx/ssl \
		--network=myproxy \
		--restart=always \
		registry.cn-shanghai.aliyuncs.com/yeqing112/nginx:1.19.1
	# phpmyadmin
	docker run -d --name myadmin \
		--link mysql57:db \
		-p 8080:80 \
		--network=myproxy \
		registry.cn-shanghai.aliyuncs.com/yeqing112/phpmyadmin:latest
}

createDB(){
	docker cp /data/db.sh mysql57:/home/db.sh
	docker exec -it mysql57 chmod +x /home/db.sh
	docker exec -it mysql57 /bin/bash /home/db.sh && docker exec -it mysql57 /bin/bash /home/db.sh
}

cleanup(){
    echo -e "\033[32m 恭喜您,安装成功.在浏览器输入域名即可访问. \033[0m"
}

echo "------------------------------------------"
echo "   欢迎使用PHP7.2网站环境一键安装脚本!  "
echo "------------------------------------------"
echo "           脚本将完成以下内容:"
echo "           1. 配置网站域名"
echo "           2. 配置网站端口"
echo "           3. 选择PHP版本"
echo "           3. 安装MySQL 5.7"
echo "           4. 安装PHP 7.2"
echo "           5. 安装Nginx 1.19"
echo "           6. 安装PhpMyAdmin"
echo "------------------------------------------"

inputData
downloadConfig
setupWebsite
dockerRun
createDB
cleanup
