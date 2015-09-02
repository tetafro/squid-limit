#!/bin/bash
BAD_USERS="/etc/squid3/bad_users.acl"
URL_BLOCK="http://error.proxy"
while read INPUT
do
    URL=$(echo $INPUT | awk '{print $1}')
    CLIENT_IP=$(echo $INPUT | awk '{print $2}')
    CLIENT_LOGIN=$(echo $INPUT | awk '{print $3}')
    QUERY=$(echo $INPUT | awk '{print $4}')
    SERVER_IP=$(echo $INPUT | awk '{print $5}')
    SERVER_PORT=$(echo $INPUT | awk '{print $6}')
    if [ "$(grep $CLIENT_LOGIN $BAD_USERS)" == "" ]
    then
        echo "$URL $CLIENT_IP $CLIENT_LOGIN $QUERY $SERVER_IP $SERVER_PORT"
    else
        echo "$URL_BLOCK $CLIENT_IP $CLIENT_LOGIN $QUERY $SERVER_IP $SERVER_PORT"
    fi
done
