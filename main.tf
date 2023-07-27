
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "mainvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name : "mainvpc"
  }
}

// vpc 안에서 서브넷 집단 하나를 만듦
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.mainvpc.id
  tags = {
    Name : "cluster_subnet"
  }

  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "cluster_sg" {
  vpc_id = aws_vpc.mainvpc.id
  name = "cluster_sg"

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "control_cluster" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t3.nano"
  key_name = "Choigonyok"

  tags = {
    Name = "control_cluster"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("../PEMKEY/Choigonyok.pem")
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo snap install aws-cli",
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
    ]
  }
}

resource "aws_instance" "master_node" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t3.nano"
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "master_node"
  }
}

resource "aws_instance" "worker_nodes" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t3.nano"
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  subnet_id = aws_subnet.public_subnet.id

  count = 2

  tags = {
    Name = "worker_node${count.index}"
  }
}

output "manager_ip" {
  value = "${aws_security_group.cluster_sg.id}"
}

output "ipaddr" {
  value = "${aws_instance.control_cluster.public_ip}"
}