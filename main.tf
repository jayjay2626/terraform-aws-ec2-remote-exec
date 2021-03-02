terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

// aws provider
provider "aws" {
  profile                 = "default"
  region                  = "us-east-1"
  shared_credentials_file = "credentials"
}


// ec2 vm instance
resource "aws_instance" "web" {
  // ubuntu 20.04 amazon image Id copied
  ami           = "ami-03d315ad33b9d49c4"
  instance_type = "t2.micro"

  // passing ssh key 
  key_name = "jayjay"

  // passing the security group resource id
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  // local provisioner
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.public_ip} >> private_ips.txt"
  }


  // remote provisioner
  provisioner "remote-exec" {

    connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.web.public_ip}"
    private_key = "${file("aws_jayjay_key.pem")}"
    agent = false
    timeout = "2m"
    }
    // install jenkins
    inline = [
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install openjdk-11-jdk -y",
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt update && sudo apt install jenkins -y",
      //"sudo cat /var/lib/jenkins/secrets/initialAdminPassword >> jenkins_password.txt"
    ]
  }

  tags = {
    Name = "rangeley826-flaskapp"
  }
}


// provisioner install-jenkins
# resource "null_resource" "install-jenkins" {

#   # connection {
#   #   type = "ssh"
#   #   host = aws_instance.web.public_ip
#   #   user = "ec2-user"
#   #   private_key = file("aws_jayjay_key.pem")
#   # }

#   // file provisioner
#   provisioner "file" {
#     source      = "install-jenkins.sh"
#     destination = "/tmp/install-jenkins.sh"
#   }

#   // remote provisioner
#   provisioner "remote-exec" {
#     inline = [
#       "sudo chmod 777 /tmp/install-jenkins.sh",
#       "/tmp/install-jenkins.sh args",
#     ]
#   }

#   // run this after ec2 created
#   depends_on = [aws_instance.web]

# }


// create custom security group
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow ssh http https jenkins inbound traffic"

  // ssh port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // http port 80 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // https port 443 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // jenkins port 8080 
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

output "ec2_web_public_ip" {
  value = aws_instance.web.public_ip
}




