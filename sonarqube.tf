resource "aws_instance" "sonarqube_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet-public-1.id
  user_data              = filebase64("user-data-sonar.sh")
  vpc_security_group_ids = [aws_security_group.sonarQube-SG.id]
  key_name               = "tfbest"  # Replace with your AWS key pair name

  tags = {
    Name = "SonarQube VM"
  }
}

resource "aws_security_group" "sonarQube-SG" {
  name        = "sonarQube-SG"
  description = "Allow port 9000 inbound traffic and all outbound traffic"
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
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sonarQube-SG.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sonarQube-SG.id
}

resource "aws_security_group_rule" "outbound_allow_all_sonar" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
 

