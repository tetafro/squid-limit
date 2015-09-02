#!/bin/bash
ACL=/etc/squid3/bad_users.acl
SQUID=/usr/sbin/squid3
USERLIST=/etc/squid3/user_login
LOG=/var/log/squid3/access.log
LOG_MONTH=/var/log/squid3/access_month.log
QUERY=/tmp/query.sql
LOG_TMP=/tmp/access.log
NO_LIMIT="-e odnoklassniki -e kinopoisk -e macromedia -e rambler -e amur.info -e amur.net -e kontur -e dms -e proxy -e buh04"
DB_USER="squid"
DB_PASS="squid"
DB="squid"
DB_TABLE="logdb"

# Сформировать файл, в котором не упоминаются обращения к безлимитным ресурсам
grep -v -e ' - ' $NO_LIMIT $LOG > $LOG_TMP
# awk выбирает нужные поля из лога формирует SQL-запрос во временном файле
awk '$4~/TCP_HIT|TCP_MISS|TCP_REFRESH_HIT/ {gsub("\"", "\\\"", $7); printf "INSERT INTO logdb (date, ip, size, link, login) VALUES (FROM_UNIXTIME(\"%s\"), \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $3, $5, $7, $8}' $LOG_TMP > $QUERY
# SQL-запрос применяется к базе
mysql -u$DB_USER -p$DB_PASS -D$DB < $QUERY
# Очистить список заблокированных пользователей
:>$ACL

# Считать список пользователей и пересчитать трафик для каждого
exec<$USERLIST
while read line
do
    # Логин, лимит и текущее значение трафика из файла
    LOGIN=$(echo $line|awk '{print $1}')
    PASS=$(echo $line|awk '{print $2}')
    LIMIT=$(echo $line|awk '{print $3}')
    CURRENT=$(echo $line|awk '{print $4}')
    FULLNAME=$(echo $line|awk '{print $5 " " $6}')
    # Считать трафик из БД и прибавить к текущему набранному значению (из файла)
    MONTH=$(date +%m)
    echo "SELECT SUM(size) FROM $DB_TABLE WHERE login=\"$LOGIN\" and MONTH(date)=\"$MONTH\";" > $QUERY
    RESULT=$(mysql -u$DB_USER -p$DB_PASS -D$DB --skip-column-names < $QUERY)
    if [ "$RESULT" == "" ]; then
        RESULT=0
    fi
    let "RESULT=$RESULT/1024/1024"
    let "CURRENT=$CURRENT+$RESULT"
    # Блокировка при превышении лимита
    if [[ "$CURRENT" -ge "$LIMIT" && "$LOGIN" != "law03" ]]; then
        echo $LOGIN >> $ACL
    fi
    # Cформировать файл user_login с новыми значениями текущего трафика
    echo -e "$LOGIN\t$PASS\t$LIMIT\t$CURRENT\t$FULLNAME" >> $USERLIST.tmp
done

# Удалить временный файл с пользователями
mv -f $USERLIST.tmp $USERLIST
# Перезапуск Squid с новым списком заблоченных пользователей
$SQUID -k reconfigure
# Прибавить новый лог к старым и запустить парсер lightsquid
cat $LOG_TMP>>$LOG_MONTH
/var/www/sites/detail.proxy/lightparser.pl $LOG_MONTH
# Очистить логи, таблицу SQL и удалить запросы
:>$LOG
echo "DELETE FROM $DB_TABLE;" > $QUERY
mysql -u$DB_USER -p$DB_PASS -D$DB < $QUERY
rm -f $QUERY $LOG_TMP
