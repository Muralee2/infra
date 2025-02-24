#!/bin/bash
set -ex

exec > /var/log/user-data.log 2>&1

sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf

sudo apt update
sudo apt upgrade -y
sudo apt install unzip -y

# Install Java (OpenJDK 17 is recommended for SonarQube)
sudo apt install openjdk-17-jdk -y

# Install PostgreSQL and Create Database
sudo apt install postgresql postgresql-contrib -y
sudo -u postgres psql -c "CREATE DATABASE sonarqube;"
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'your_strong_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

# Download and Extract SonarQube
SONARQUBE_VERSION=10.5.1.90531
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONARQUBE_VERSION.zip
sudo unzip sonarqube-$SONARQUBE_VERSION.zip -d /opt/
sudo mv /opt/sonarqube-$SONARQUBE_VERSION /opt/sonarqube

# Configure SonarQube
sudo tee /opt/sonarqube/conf/sonar.properties <<EOL
sonar.jdbc.username=sonar
sonar.jdbc.password=your_strong_password
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
EOL

# Create a System User for SonarQube
sudo useradd -M -d /opt/sonarqube -u 998 -r -s /bin/bash sonar
sudo chown -R sonar:sonar /opt/sonarqube

# Create a Systemd Service
sudo tee /etc/systemd/system/sonarqube.service <<EOL
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable and Start SonarQube Service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sysctl vm.max_map_count

sudo systemctl restart sonarqube

# Capture logs
sleep 30
sudo journalctl -u sonarqube --no-pager --lines=50 > /var/log/sonarqube.log
