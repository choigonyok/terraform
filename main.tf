
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
  map_public_ip_on_launch = true
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "IGW" {
    vpc_id =  aws_vpc.mainvpc.id
}

resource "aws_route_table" "PublicRT" {
    vpc_id =  aws_vpc.mainvpc.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
    }
}

resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.PublicRT.id
}

resource "aws_security_group" "cluster_sg" {
  vpc_id = aws_vpc.mainvpc.id
  name = "cluster_sg"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "master_node" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  key_name = "Choigonyok"

  tags = {
    Name = "master_node"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("../PEMKEY/Choigonyok.pem")    
    host = self.public_ip
  }

   provisioner "remote-exec" {

    inline = [
      "git clone https://github.com/wardviaene/on-prem-or-cloud-agnostic-kubernetes.git",
      "cd on-prem-or-cloud-agnostic-kubernetes",
      "yes | sudo scripts/install-kubernetes.sh",
    ]
  }
}

resource "aws_instance" "worker_nodes" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  key_name = "Choigonyok"

  count = 2

  tags = {
    Name = "worker_node${count.index}"
  }  

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("../PEMKEY/Choigonyok.pem")    
    host = self.public_ip
  }
   
  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/wardviaene/on-prem-or-cloud-agnostic-kubernetes.git",
      "cd on-prem-or-cloud-agnostic-kubernetes",
      "yes | sudo scripts/install-node.sh",
    ]
  }
}

output "master-ip" {
  value = "${aws_instance.master_node.public_ip}"
}

output "worker1-ip" {
  value = "${aws_instance.worker_nodes[0].public_ip}"
}

output "worker2-ip" {
  value = "${aws_instance.worker_nodes[1].public_ip}"
}

# master는 
# nodes는 sudo scripts/install-node.sh

# master에 나온 join 명령어 node에서 실행

# master : vim scripts/create-user.sh
# 들어가서
#     useradd => usermod 변경
#     맨위에 groupadd ubuntu? 삭제
# result=$(sudo scripts/install-kubernetes.sh | grep -o "hello")
# "result=$(yes | sudo scripts/install-kubernetes.sh | grep -o 'kubeadm join [^\n]*')"
# result=$(yes | sudo scripts/install-kubernetes.sh | grep -o '^kubeadm join .*')
# echo "$result" > ../result.txt,

# vim scripts/create-user.sh
# sudo scripts/create-user.sh

# sudo kubelet ~