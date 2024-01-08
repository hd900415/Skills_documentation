 --Mysql 常用SQL
 --create database set character MySQL的“utf8mb4”是真正的“UTF-8”
   create database grafana character set UTF8mb4 collate utf8mb4_bin;
   CREATE DATABASE nj28 DEFAULT CHARACTER SET utf32 COLLATE utf32_general_ci;
   CREATE DATABASE hwyl DEFAULT CHARACTER SET utf32 COLLATE utf32_general_ci;
 --create user
    --5.7
    GRANT ALL ON database.* TO 'sqluser'@'localhost' IDENTIFIED BY 'secret';   ---grafana123
    --8+
    CREATE USER 'sqluser'@'localhost' IDENTIFIED BY 'secret';
    GRANT ALL PRIVILEGES  ON database.* TO 'sqluser'@'localhost';
    grant select on wlgj.* to 'kaifa'@'87.200.168.93';
   --刷新权限

   flush privileges;



-- show databases;显示当前数据库
   select database();


-- 查看当前密码策略--MySQL ERROR 1819 (HY000): Your password does not satisfy the current policy requirements
   SHOW VARIABLES LIKE 'validate_password%';
-- msyqldum 备份数据库
mysqldump -h yhwpmmg-db.coq9b7cyv5zl.ap-east-1.rds.amazonaws.com -u kpdfnru07 -p --set-gtid-purged=OFF --databases dbname > dbname.sql


-- 显示表 columnt的备注或描述信息
show full columns from table_name;




