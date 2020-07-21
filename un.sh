#!/bin/bash

delDir(){
	# 删除目录与文件
	rm -rf /data/s.sh
	rm -rf /data/nginx
	rm -rf /data/php7
	rm -rf /data/www
	rm -rf /data/data
}

rmContainer(){
	# 删除容器
	docker rm -f myadmin
	docker rm -f nginx
	docker rm -f php_fpm
	docker rm -f mysql57
}

cleanup(){
    echo -e "\033[32m 已经清理干净了. \033[0m"
}

delDir
rmContainer
cleanup
