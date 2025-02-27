#!/bin/bash
set -euxo pipefail  # Enable strict error handling

exec > /var/log/sonarqube-setup.log 2>&1  # Redirect all output to log file

# Update system and install required packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y unzip openjdk-17-jdk postgresql postgresql-contrib wget curl

# Configure PostgreSQL for SonarQube
SONAR_DB="sonarqube"
SONAR_USER="sonar"
SONAR_PASSWORD=$(openssl rand -base64 16)  # Generate a secure password

sudo -u postgres psql <<EOF
CREATE DATABASE $SONAR_DB;
CREATE USER $SONAR_USER WITH ENCRYPTED PASSWORD '$SONAR_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $SONAR_DB TO $SONAR_USER;
ALTER ROLE $SONAR_USER WITH LOGIN;
REVOKE CONNECT ON DATABASE $SONAR_DB FROM PUBLIC;
EOF

# Fetch SonarQube version from Terraform variable
SONARQUBE_VERSION="${SONARQUBE_VERSION}"

# Download and Extract SonarQube
wget -q "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip"
sudo unzip "sonarqube-${SONARQUBE_VERSION}.zip" -d /opt/
sudo mv "/opt/sonarqube-${SONARQUBE_VERSION}" /opt/sonarqube

# Configure SonarQube database connection
sudo tee /opt/sonarqube/conf/sonar.properties > /dev/null <<EOL
sonar.jdbc.username=$SONAR_USER
sonar.jdbc.password=$SONAR_PASSWORD
sonar.jdbc.url=jdbc:postgresql://localhost/$SONAR_DB
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false
EOL

# Create a dedicated SonarQube user
sudo useradd -m -d /opt/sonarqube -u 998 -r -s /bin/bash sonar
sudo chown -R sonar:sonar /opt/sonarqube
sudo chmod -R 775 /opt/sonarqube

# Optimize system settings for SonarQube
sudo tee -a /etc/sysctl.conf > /dev/null <<EOL
vm.max_map_count=262144
fs.file-max=65536
EOL
sudo sysctl --system

sudo tee -a /etc/security/limits.conf > /dev/null <<EOL
sonar   -   nofile   65536
sonar   -   nproc    4096
EOL

# Create Systemd Service for SonarQube
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOL
[Unit]
Description=SonarQube service
After=network.target postgresql.service

[Service]
Type=simple
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

# Allow SonarQube port in firewall (if UFW is enabled)
if sudo ufw status | grep -q "active"; then
    sudo ufw allow 9000/tcp
    sudo ufw reload
fi

# Capture logs for debugging
sleep 30
sudo journalctl -u sonarqube --no-pager --lines=50 > /var/log/sonarqube.log

echo "SonarQube setup completed successfully!"
