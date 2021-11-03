locals {
  
  ssh_user = "ubuntu"
  key_name= "zabbix-aws"
}

provider "aws" {
   region     = "us-east-1"
   
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 22
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "all"
     security_groups  = []
     self             = false
     to_port          = 22
  }
  ]
}


resource "aws_security_group" "zabbix" {
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 10050 
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "all"
     security_groups  = []
     self             = false
     to_port          = 10050
  }
  ]
}

resource "aws_instance" "zabbix" {

    ami = data.aws_ami.ubuntu.id  
    instance_type = "t2.micro" 
    key_name= local.key_name
    vpc_security_group_ids = [aws_security_group.main.id]
    associate_public_ip_address = true

    user_data = <<-EOF
      #!/bin/bash
      wget https://repo.zabbix.com/zabbix/5.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.4-1+ubuntu20.04_all.deb
      dpkg -i zabbix-release_5.4-1+ubuntu20.04_all.deb
      apt update -qq
      sudo apt-get remove docker docker-engine docker.io containerd runc
      sudo apt-get install ca-certificates curl gnupg lsb-release -y
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update -qq
      sudo apt-get install docker-ce docker-ce-cli containerd.io -y
      sudo systemctl enable docker
      sudo systemctl start docker
      systemctl adduser ubuntu docker
      sudo apt-get install zip -y
      sudo apt-get install zcat
      sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
      sudo apt install software-properties-common
      sudo add-apt-repository --yes --update ppa:ansible/ansible
      sudo apt install ansible -y
      sudo apt install git -y
      sudo timedatectl set-timezone America/Sao_Paulo
      git clone https://github.com/lucasrf1984/terraform
      EOF
}

output "zabbix_ip" {
  value = aws_instance.zabbix.public_ip
}