#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop/"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'

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

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying the mongo repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing mongodb"

systemctl enable mongod &>>$LOGS_FILE
systemctl start mongod 
VALIDATE $? "Enabling the mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Validating the conf"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting mongod"


