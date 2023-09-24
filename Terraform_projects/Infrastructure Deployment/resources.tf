# deployment of a VPC, subnets, security groups, and EC2 instances.

#---------------------------------VPC----------------------------------------
# resource "aws_instance" "myvpc" {
#   ami = "ami-0b9094fa2b07038b8"
#   instance_type = "t2.micro" 
# }

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project 1"
  }

}

#---------------------------------SUBNETS----------------------------------------
#-----------Public------------------

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs
  availability_zone = var.avail_zone

  tags = { 
    Name = "Public subnet"
  }
}

#-----------Private------------------
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = var.avail_zone


  tags = {
    Name = "Private subnet ${count.index + 1}"
  }
}

#---------------------------------INTERNET GATEWAY----------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}


#---------------------------------ROUTE TABLE----------------------------------------
resource "aws_route_table" "my_routes" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
}

#---------------------------------ROUTE TABLE ASSOCIATION----------------------------------------
# This will help associate the subnet with the route table 
#Only be using the public subnet for this example

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_routes.id
}

#---------------------------------SECURITY GROUP----------------------------------------
# ports  22,80,443

resource "aws_security_group" "sec_grp1" {
  name = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ] # To allow all the ips to access "0.0.0.0/0" 
  }

    ingress {
    description = "HTTPS"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ] # To allow all the ips to access "0.0.0.0/0" 
  }

    ingress {
    description = "SSH"
    from_port = 20
    to_port = 20
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ] # To allow all the ips to access "0.0.0.0/0" 
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"   # -1 means any protocol    
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name = "allow_web"
  }
}

#---------------------------------NETWORK INTERFACE----------------------------------------
# This helps create a private IP for the host

resource "aws_network_interface" "interface_1" {
  subnet_id       = aws_subnet.public_subnet.id
  private_ips     = [var.interface_1_private_ip]
  security_groups = [aws_security_group.sec_grp1.id]
}

#---------------------------------ELASTIC IP----------------------------------------
# This helps create a public IP for access

resource "aws_eip" "e_ip_1" {
  domain = "vpc"
  network_interface = aws_network_interface.interface_1.id
  associate_with_private_ip = var.interface_1_private_ip  # AS we are passing the same range of provate Ips as above
  depends_on = [aws_internet_gateway.gw]
}

#---------------------------------EC2 instance----------------------------------------

resource "aws_instance" "myec2_1" {
  ami = "ami-01342111f883d5e4e"
  instance_type = "t2.micro"
  availability_zone = var.avail_zone    # We give a common availability zone to subnet and E2 instance so that they are launched in the same zone 
                                        # Or aws might launch them in different zones
  network_interface {
    device_index = 0 
    network_interface_id = aws_network_interface.interface_1.id

  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install eapache2 -y
              sudo systemctl start eapache2
              EOF
  
  tags = {
    Name = "web_server_ec2"
  } 
}