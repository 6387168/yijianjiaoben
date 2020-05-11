#!/bin/bash
  
DATADIR='/data/mysql/data'
VERSION='mysql-5.5.49'
export LANG=zh_CN.UTF-8
  
#Source function library.
. /etc/init.d/functions
  
#camke install mysql5.5.X
install_mysql(){
        read -p "please input a password for root: " PASSWD
        if [ ! -d $DATADIR ];then
                mkdir -p $DATADIR
        fi
        yum install cmake make gcc-c++ bison-devel ncurses-devel -y
        id mysql &>/dev/null
        if [ $? -ne 0 ];then
                useradd mysql -s /sbin/nologin -M
        fi
        #useradd mysql -s /sbin/nologin -M
        #change datadir owner to mysql
        chown -R mysql.mysql $DATADIR
        cd
        wget http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.49.tar.gz
        tar xf $VERSION.tar.gz
        cd $VERSION
        cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/$VERSION \
        -DMYSQL_DATADIR=$DATADIR \
        -DMYSQL_UNIX_ADDR=$DATADIR/mysql.sock \
        -DDEFAULT_CHARSET=utf8 \
        -DDEFAULT_COLLATION=utf8_general_ci \
        -DENABLED_LOCAL_INFILE=ON \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
        -DWITHOUT_PARTITION_STORAGE_ENGINE=1
        make && make install
        if [ $? -ne 0 ];then
                action "install mysql is failed"  /bin/false
                exit $?
        fi
        sleep 2
        #link
        ln -s /usr/local/$VERSION/ /usr/local/mysql
        ln -s /usr/local/mysql/bin/* /usr/bin/
        #copy config and start file
        /bin/cp /usr/local/mysql/support-files/my-small.cnf /etc/my.cnf
        cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
        chmod 700 /etc/init.d/mysqld
        #init mysql
        /usr/local/mysql/scripts/mysql_install_db  --basedir=/usr/local/mysql --datadir=$DATADIR --user=mysql
        if [ $? -ne 0 ];then
                action "install mysql is failed"  /bin/false
                exit $?
        fi
        #check mysql
        /etc/init.d/mysqld start
        if [ $? -ne 0 ];then
                action "mysql start is failed"  /bin/false
                exit $?
        fi
        chkconfig --add mysqld
        chkconfig mysqld on
        /usr/local/mysql/bin/mysql -e "update mysql.user set password=password('$PASSWD') where host='localhost' and user='root';"
        /usr/local/mysql/bin/mysql -e "update mysql.user set password=password('$PASSWD') where host='127.0.0.1' and user='root';"
        /usr/local/mysql/bin/mysql -e "delete from mysql.user where password='';"
        /usr/local/mysql/bin/mysql -e "flush privileges;"
        #/usr/local/mysql/bin/mysql -e "select version();" >/dev/null 2>&1
        if [ $? -eq 0 ];then
                echo "+---------------------------+"
                echo "+------mysql安装完成--------+"
                echo "+---------------------------+"
        fi
        #/etc/init.d/mysqld stop
}
  
install_mysql
