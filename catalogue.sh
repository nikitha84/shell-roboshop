
# TIMESTAMP=$(date +%F-%H-%M-%S)
# LOGFILE="/tmp/$0-$TIMESTAMP.log"
# echo "script executed at $TIMESTAMP" &>> $LOGFILE

#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongodb.nikitha.fun
SCRIPT_DIR=$PWD #/home/shell-roboshop/catalogue.sh
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabled nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabled nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi


mkdir -p /app &>>$LOG_FILE
VALIDATE $? "created app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloade catalogue file"

cd /app  &>>$LOG_FILE
VALIDATE $? "changing to app directory"

unzip -o /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unziped catalogue file"

npm install  &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Coping catalogue service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "deamon reloaded"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "ebnabled catalogue"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "stttaared catalogue"

cp  $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copied mongodb repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installed mongodb shell"

INDEX=$(mongosh mongodb.nikitha.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemct restart catalogue &>>$LOG_FILE
VALIDATE $? "restart catalogue"

#run
#netstat
#curl http://localhost:8080/health