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

if [ $ID -ne 0 ]
then
    echo -e "$R ERROR: please run with root user $N"
    exit 1
else
    echo -e "$G you are root user $N"
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabled nodejs"

dnf module enable nodejs:20 -y &>> $LOGFILE
VALIDATE $? "enabled nodejs"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "install nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGFILE
VALIDATE $? "created system user"

mkdir -p /app &>> $LOGFILE
VALIDATE $? "created app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>> $LOGFILE
VALIDATE $? "Downloade catalogue file"

cd /app  &>> $LOGFILE

unzip -o /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "Unziped catalogue file"

npm install  &>> $LOGFILE
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/shell-roboshop/catalogue.service /etc/systemd/system/catalogue.service&>> $LOGFILE
VALIDATE $? "Coping catalogue service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "deamon reloaded"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "ebnabled caalogue"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "stttaared cattalogue"

cp /home/ec2-user/shell-roboshop/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "copied mongodb repo"

dnf install mongodb-mongosh -y &>> $LOGFILE
VALIDATE $? "installed mongodb shell"

mongosh --host 172.31.26.147 </app/db/master-data.js &>> $LOGFILE
VALIDATE $? "loading caatalogue data into mongodb"

