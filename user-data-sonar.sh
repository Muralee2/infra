#!/bin/bash
set -euxo pipefail  # Enable strict error handling

exec > /var/log/sonarqube-setup.log 2>&1  # Redirect all output to log file

# Update system and install required packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y unzip openjdk-17-jdk postgresql postgresql-contrib wget

# Configure PostgreSQL for SonarQube
SONAR_DB="sonarqube"
SONAR_USER="sonar"
SONAR_PASSWORD=$(openssl rand -base64 16)  # Generate a secure password

sudo -u postgres psql -c "CREATE DATABASE $SONAR_DB;"
sudo -u postgres psql -c "CREATE USER $SONAR_USER WITH ENCRYPTED PASSWORD '$SONAR_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $SONAR_DB TO $SONAR_USER;"
sudo -u postgres psql -c "ALTER ROLE $SONAR_USER WITH LOGIN;"
sudo -u postgres psql -c "REVOKE CONNECT ON DATABASE $SONAR_DB FROM PUBLIC;"

# Install SonarQube
SONARQUBE_VERSION="10.5.1.90531"
wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONARQUBE_VERSION.zip
sudo unzip sonarqube-$SONARQUBE_VERSION.zip -d /opt/
sudo mv /opt/sonarqube-$SONARQUBE_VERSION /opt/sonarqube

# Configure SonarQube database connection
sudo tee /opt/sonarqube/conf/sonar.properties > /dev/null <<EOL
sonar.jdbc.username=$SONAR_USER
sonar.jdbc.password=$SONAR_PASSWORD
sonar.jdbc.url=jdbc:postgresql://localhost/$SONAR_DB
sonar.web.host=0.0.0.0
sonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false
EOL

# Create a dedicated SonarQube user
sudo useradd -M -d /opt/sonarqube -u 998 -r -s /bin/bash sonar
sudo chown -R sonar:sonar /opt/sonarqube

# Optimize system settings for SonarQube
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Create Systemd Service for SonarQube
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOL
[Unit]
Description=SonarQube service
After=syslog.target network.target postgresql.service

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOL

# Enable and start SonarQube service
sudo systemctl daemon-reload
sudo systemctl enable --now sonarqube

# Capture logs for debugging
sleep 30
sudo journalctl -u sonarqube --no-pager --lines=50 > /var/log/sonarqube.log

echo "SonarQube setup completed successfully!"

