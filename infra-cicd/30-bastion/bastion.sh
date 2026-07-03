#!/bin/bash
USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME="bastion"
LOGFILE=/var/log/$SCRIPT_NAME-$TIMESTAMP.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...${R} FAILURE ${N}" | tee -a $LOGFILE
        exit 1
    else
        echo -e "$2...${G} SUCCESS ${N}" | tee -a $LOGFILE
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access." | tee -a $LOGFILE
    exit 1
else
    echo "You are super user." | tee -a $LOGFILE
fi

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "install mysql"

# docker
yum install -y yum-utils &>>$LOGFILE
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>>$LOGFILE
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y &>>$LOGFILE
systemctl start docker &>>$LOGFILE
systemctl enable docker &>>$LOGFILE
usermod -aG docker ec2-user &>>$LOGFILE
VALIDATE $? "Docker installation"

# eksctl
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" &>>$LOGFILE
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
mv /tmp/eksctl /usr/local/bin
eksctl version &>>$LOGFILE
VALIDATE $? "eksctl installation"

# kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.0/2024-09-12/bin/linux/amd64/kubectl &>>$LOGFILE
chmod +x ./kubectl
mv kubectl /usr/local/bin/kubectl
VALIDATE $? "kubectl installation"

# kubens
git clone https://github.com/ahmetb/kubectx /opt/kubectx &>>$LOGFILE
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
VALIDATE $? "kubens installation"

# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &>>$LOGFILE
chmod 700 get_helm.sh
./get_helm.sh &>>$LOGFILE
VALIDATE $? "helm installation"

# k9s
curl -sS https://webinstall.dev/k9s | bash &>>$LOGFILE
VALIDATE $? "K9S installation"
