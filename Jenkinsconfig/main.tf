resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ami_info.id
  instance_type          = "t3.small"
  subnet_id              = "subnet-091d9fd871f772c58"
  vpc_security_group_ids = ["sg-06379eec176b454ce"]
  user_data              = file("jenkins.sh")

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "jenkins"
  }
}

resource "aws_instance" "jenkins_agent" {
  ami                    = data.aws_ami.ami_info.id
  instance_type          = "t3.small"
  subnet_id              = "subnet-091d9fd871f772c58"
  vpc_security_group_ids = ["sg-06379eec176b454ce"]
  user_data              = file("jenkins-agent.sh")

  root_block_device {
    volume_size           = 50 #size of the root volume in GB 
    volume_type           = "gp3"
    delete_on_termination = true #automatically delete when instance is delete 
  }

  tags = {
    Name = "jenkins_agent"
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        aws_instance.jenkins.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        aws_instance.jenkins_agent.private_ip
      ]
      allow_overwrite = true
    }
  ]
}