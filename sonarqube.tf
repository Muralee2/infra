resource "aws_instance" "sonarqube_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium" # Upgraded for better performance
  subnet_id              = aws_subnet.subnet-public-1.id
  user_data = templatefile("${path.module}/user-data-sonar.sh", {
    SONARQUBE_VERSION = "25.1.0.102122"  # Replace with the latest version if needed
  })
  vpc_security_group_ids = [aws_security_group.sonarQube-SG.id]
  key_name               = "tfbest"

  tags = {
    Name = "SonarQube VM"
  }

  depends_on = [aws_instance.postgresql_vm]  # Ensure PostgreSQL is ready before SonarQube starts
}

# Security Group for SonarQube
resource "aws_security_group" "sonarQube-SG" {
  name        = "sonarQube-SG"
  description = "Allow port 9000 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.webapp_VPC.id

  tags = {
    Name = "sonarQube-SG"
  }
}

# Allow HTTP access on SonarQube port 9000
resource "aws_security_group_rule" "allow_port_9000_to_sonar_VM" {
  type              = "ingress"
  from_port         = 9000
  to_port           = 9000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Open for all (Restrict in production)
  security_group_id = aws_security_group.sonarQube-SG.id
}

# Allow SSH access only from your IP
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["103.179.211.117/32"]  # Replace with your IP
  security_group_id = aws_security_group.sonarQube-SG.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "outbound_allow_all_sonar" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sonarQube-SG.id
}

# Ensure SonarQube is accessible before proceeding
resource "null_resource" "wait_for_sonarqube" {
  provisioner "local-exec" {
    command = <<EOT
    echo "Waiting for SonarQube to start..."
    timeout 600 bash -c 'until curl --output /dev/null --silent --head --fail http://${aws_instance.sonarqube_vm.public_ip}:9000; do 
      echo "Still waiting for SonarQube...";
      sleep 10;
    done'
    echo "SonarQube is now reachable!"
    EOT
  }

  depends_on = [aws_instance.sonarqube_vm]
}
