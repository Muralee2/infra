#!/bin/bash
set -ex

# Redirect all output to a log file
exec > /var/log/user-data.log 2>&1

# Update and upgrade the system
sudo apt update
sudo apt upgrade -y
sudo apt install unzip -y

# Install Java (OpenJDK 17 is recommended for SonarQube)
sudo apt install openjdk-17-jdk -y

# Install PostgreSQL and create the SonarQube database and user
sudo apt install postgresql postgresql-contrib -y
sudo -u postgres psql -c "CREATE DATABASE sonarqube;"
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'M@sonardata23';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

# Download and extract the latest SonarQube version
SONARQUBE_VERSION=25.1.0.102122
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
sudo unzip sonarqube-${SONARQUBE_VERSION}.zip -d /opt/
sudo mv /opt/sonarqube-${SONARQUBE_VERSION} /opt/sonarqube

# Configure SonarQube
sudo tee /opt/sonarqube/conf/sonar.properties > /dev/null <<EOL
sonar.jdbc.username=sonar
sonar.jdbc.password=your_strong_password
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
EOL

# Create a system user for SonarQube
sudo useradd -M -d /opt/sonarqube -r -s /bin/bash sonar
sudo chown -R sonar:sonar /opt/sonarqube

# Create a systemd service for SonarQube
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOL
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

# Enable and start the SonarQube service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

# Set system configurations for SonarQube
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Restart SonarQube to apply configurations
sudo systemctl restart sonarqube

# Capture the last 50 lines of SonarQube logs
sleep 30
sudo journalctl -u sonarqube --no-pager --lines=50 > /var/log/sonarqube.log

