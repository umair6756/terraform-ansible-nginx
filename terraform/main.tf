# main.tf 

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    }
}

data "aws_vpc" "default" {
  default = true
}


resource "aws_key_pair" "docker-key-ubuntu-123" {
    key_name = "docker-key-ubuntu-123"
    public_key = file("./ssh-key/id_ed25519.pub")
}

resource "aws_security_group" "docker-ubuntu-sg" {
  name = "docker-ubuntu-sg"
  vpc_id = data.aws_vpc.default.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

      egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "docker-ubuntu" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.docker-key-ubuntu-123.key_name

  vpc_security_group_ids = [aws_security_group.docker-ubuntu-sg.id]
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              EOF
}

output "instance_ip" {
  value = aws_instance.docker-ubuntu.public_ip
}



