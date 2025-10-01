#!/bin/bash
ID=(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"
echo "script executed at $TIMESTAMP" &>> $LOGFILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$R ERROR: $1  ... Failed $N"
        exit 1
    else
        echo -e "$G $2 ....Success $N"
    fi        
}

if [ $ID -ne 0 ];
then
    echo -e "$R ERROR: please run with root user $N"
    exit 1
else
    echo -e "$G you are root user $N"
fi

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "copied mongo.repo"

dnf install mongodb-org -y  &>> $LOGFILE
VALIDATE $? "installed mongodb"

systemctl enable mongod  &>> $LOGFILE
VALIDATE $? "enabled mongodb"

systemctl start mongod  &>> $LOGFILE
VALIDATE $? "started mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGFILE
VALIDATE $? "remote access to mongodb"

systemctl restart mongod &>> $LOGFILE
VALIDATE $? "restarted to mongodb"