#!/bin/bash
HOSTNAME="mysql57"
PORT="3306"
USERNAME="root"
PASSWORD="{w:password:w}"
DBNAME="{w:dbname:w}"
#创建数据库
create_db_sql="create database IF NOT EXISTS ${DBNAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "${create_db_sql}" 2>/dev/null