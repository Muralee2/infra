variable "my_ip" {
  default = "103.179.211.117/32"  # Your actual IP in string format
}

variable "sonarqube_version" {
  default = "10.5.1.90531"  # Fallback version if fetch fails
}

resource "aws_instance" "sonarqube_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.subnet-public-1.id
  user_data              = templatefile("${path.module}/user-data-sonar.sh", { 
    SONARQUBE_VERSION = var.sonarqube_version
  })
  vpc_security_group_ids = [aws_security_group.sonarQube-SG.id]
  key_name               = "tfbest"

  tags = {
    Name = "SonarQube VM"
  }
}

resource "aws_security_group" "sonarQube-SG" {
  name        = "sonarQube-SG"
  description = "Allow SonarQube access"
  vpc_id      = aws_vpc.webapp_VPC.id

  tags = {
    Name = "sonarQube-SG"
  }
}

resource "aws_security_group_rule" "allow_port_9000_to_sonar_VM" {
  type              = "ingress"
  from_port         = 9000
  to_port           = 9000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Open to all (modify as needed)
  security_group_id = aws_security_group.sonarQube-SG.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["103.179.211.117"]  # Restrict SSH to only your IP
  security_group_id = aws_security_group.sonarQube-SG.id
}

resource "aws_security_group_rule" "outbound_allow_all_sonar" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sonarQube-SG.id
}

# Wait for SonarQube to become available
resource "null_resource" "wait_for_sonarqube" {
  provisioner "local-exec" {
    command = <<EOT
    timeout 600 bash -c 'until curl --output /dev/null --silent --head --fail http://${aws_instance.sonarqube_vm.public_ip}:9000; do 
      echo "Waiting for SonarQube...";
      sleep 10;
    done'
    echo "SonarQube is now reachable!"
    EOT
  }

  # Correct placement of depends_on
  depends_on = [aws_instance.sonarqube_vm]
}

