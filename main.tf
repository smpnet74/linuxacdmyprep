resource "aws_iam_role" "rundeckrole" {
  name = "rundeckrole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "sto-readonly-role-policy-attach" {
  role       = aws_iam_role.rundeckrole.id
  policy_arn = var.adminpolicyarn
}

resource "aws_iam_instance_profile" "rundeck" {
  name = "rundeck_profile"
  role = aws_iam_role.rundeckrole.id
}
resource "aws_key_pair" "rundeck" {
  key_name   = "rundeck-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC53shOP2UWHJzqHFnjeTDolZcaHQoXg1v0XM6lpyaZpz5RGZ1UWxw9+vbHGow4DOnD4Cvs85g5fby90RESXOsqi/PBEOOQcksuLB4FauSVKOr95NIhafxO62L/GGogdTVnSU8Bcs4ZB/OkGbMGdd2BRGS5KsUBsB+uopKCIFylA7YgwR1IW2hEofg3cDwPtnETsZVSjKSIy/ZvN8vTBrvWMyB5TGWi/zuMpJWsJ0h4GtLkJC4Cg716ajpmyGtJQHld+S+joH4Xs2Xv3wDxnrGMdmCF1bb6zvzVNFDHkB4QybKczIKXBLELQ2xXAE9nFk9TfMfubJmeYr48nUmLsT7l speterson@Scotts-MacBook-Pro.local"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = var.vpcid

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = var.vpcid
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = var.vpcid
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1d"

  tags = {
    Name = "public2"
  }
}

resource "aws_route" "r" {
  route_table_id            = var.routetableid
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_security_group" "allowssh" {
  name        = "allow_ssh"
  description = "Allow SSH from Comcast"
  vpc_id      = var.vpcid

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.110.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "rundeck" {
  ami           = "ami-0a887e401f7654935"
  instance_type = "t3.medium"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allowssh.id]
  subnet_id = aws_subnet.public1.id
  key_name = aws_key_pair.rundeck.id
  iam_instance_profile = aws_iam_instance_profile.rundeck.id

  tags = {
    Name = "rundeck"
  }
}
