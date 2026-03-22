#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop/"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.devopstest.fun

mkdir -p $LOGS_FOLDER

if [ $USER_ID -ne 0 ]; then
  echo -e "$R Please run the sript with root access $N" | tee -a $LOGS_FILE
  exit 1
fi

VALIDATE(){
  if [ $1 -ne 0 ]; then
    echo -e "$2 .... $R FAILURE $N" | tee -a $LOGS_FILE
  else
    echo -e "$2 .... $G SUCCESS $N" | tee -a $LOGS_FILE
  fi
}

dnf module disable nodejs -y
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Install nodejs"

id roboshop &>>$LOGS_FILE

if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  VALIDATE $? "Creating user"
else
  echo "User already exists"
fi

mkdir -p /app 
VALIDATE $? "Creating app folder"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $?  "Downloading the code"

cd /app 

rm -rf /app/*
VALIDATE $? "Removing data in app"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping the code"

cd /app 
npm install &>>$LOGS_FILE
VALIDATE $? "Installing npm"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload

systemctl enable catalogue &>>$LOGS_FILE
systemctl start catalogue &>>$LOGS_FILE
VALIDATE $? "Enabling the service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "Copying mongo.repo"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing client mongodb"

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"






