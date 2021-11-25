locals {

  ssh_user = "ubuntu"
  key_name= "zabbix-aws"
  private_key_path = "/home/lucas/terraform/zabbix-aws.pem"
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

  tags = {
    Name = "AWS-Zabbix"
  }

    user_data = <<-EOF
      #!/bin/bash
      wget https://repo.zabbix.com/zabbix/5.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.4-1+ubuntu20.04_all.deb
      dpkg -i zabbix-release_5.4-1+ubuntu20.04_all.deb
      EOF
}

#IP of aws instance copied to a file ip.txt in local system
resource "local_file" "ip" {
    content  = aws_instance.zabbix.public_ip
    filename = "inventory"
}

#connecting to the Ansible control node using SSH connection
resource "null_resource" "nullremote1" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file(local.private_key_path)
      host = aws_instance.zabbix.public_ip
}
    inline = ["echo 'SSH connection is finally available!'"]
}

provisioner "local-exec" {
  command = "ansible-playbook -i inventory --private-key /home/lucas/terraform/zabbix-aws.pem -u ubuntu main.yml"
}

}
output "zabbix_ip" {
  value = aws_instance.zabbix.public_ip
}
