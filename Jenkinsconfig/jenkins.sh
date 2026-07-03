#!/bin/bash
# Add Jenkins LTS repo
# curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/rpm-stable/jenkins.repo

# Install Java 21 + Jenkins
dnf install -y fontconfig java-21-openjdk jenkins

# Import Jenkins key
# rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

# yum install fontconfig java-17-openjdk jenkins -y

#resize disk from 20GB to 50GB
growpart /dev/nvme0n1 4

lvextend -L +10G /dev/RootVG/rootVol
lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -l +100%FREE /dev/mapper/RootVG-varTmpVol

xfs_growfs /
xfs_growfs /var/tmp
xfs_growfs /var

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins