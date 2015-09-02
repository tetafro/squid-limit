#!/bin/bash
# Расположение таблицы потребителей и последнего файла-отчёта
INDEX="/var/www/sites/stat.proxy/index.html"
USERLIST="/etc/squid3/user_login"
# Очистка прошлой таблицы
:>$INDEX

# Создание заголовков HTML-файла и таблицы
echo "<html>">>$INDEX
echo "<title>Статистика</title>">>$INDEX
echo "<body>">>$INDEX
echo "<b>Статистика прокси-сервера</b>">>$INDEX
echo "<br>">>$INDEX
echo "<br>">>$INDEX
echo "<table cellpadding=3 width=35% bordercolor="#333333">">>$INDEX
echo "<tr><td width=15% bgcolor="#f5f5dc"><b>Номер</b></td><td width=65% bgcolor="#f5f5dc"><b>Фамилия</b></td><td width=20% align=center bgcolor="#f5f5dc"><b>Скачано, МБ</b></td></tr>">>$INDEX

# Построчное считывание файла отчёта
COUNT="1"
exec<$USERLIST
while read line
do
    # Логин, лимит и текущее значение трафика из файла
    LOGIN=$(echo $line|awk '{print $1}')
    PASS=$(echo $line|awk '{print $2}')
    LIMIT=$(echo $line|awk '{print $3}')
    CURRENT=$(echo $line|awk '{print $4}')
    FULL_NAME=$(echo $line|awk '{print $5 " " $6}')
    # Таблица цветов (2 стандартных, красный, серый)
    COLOR=("#f5f5dc" "#fff8dc" "#f4b7b7" "#aaaaaa")
    # Выбрать цвет и занести в HTML-файл
    C=$(($COUNT % 2))
    if [ "$(($CURRENT/$LIMIT*100))" -gt 90 ] && [ "$(($CURRENT/$LIMIT*100))" -lt 100 ]
    then
        C=2
    elif [ "$(($CURRENT/$LIMIT*100))" -ge 100 ]
    then
        C=3
    fi
    echo "<tr><td bgcolor="${COLOR[$C]}">$COUNT</td><td bgcolor="${COLOR[$C]}">$FULL_NAME</td><td align=center bgcolor="${COLOR[$C]}">$CURRENT</td></tr>">>$INDEX
    COUNT=$(($COUNT+1))
done

# Закрыть таблицу и HTML-файл, подставить дату отчёта и расшифровку цветов
echo "</table>">>$INDEX
echo "<br>">>$INDEX
echo "<table cellpadding=3 width=35% bordercolor="#333333">">>$INDEX
echo "<tr><td width=15% bgcolor="#f4b7b7"></td><td width=85% bgcolor="#fff8dc">Израсходовано больше 90%</td></tr>">>$INDEX
echo "<tr><td width=15% bgcolor="#aaaaaa"></td><td width=85% bgcolor="#f5f5dc">Израсходовано 100%</td></tr>">>$INDEX
echo "</table>">>$INDEX
echo "<br>">>$INDEX
echo "Отчёт сформирован в" $(date '+%H:%M %d.%m.%y')>>$INDEX
echo "</body>">>$INDEX
echo "</html>">>$INDEX
