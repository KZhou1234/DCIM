# changes:
# 1. server name: use app_server to replace backend server
# 2. Key need to be changed
# 3. ignore userdata now 
# 4. use batsion host instead of frontend_server
# 5. security group for app: alb_sg
# 6. load balancer to app server
locals{
  # pub_key = file("kura_public_key.txt")
  app_private_ips = aws_instance.app_server[*].private_ip
}

# instance for app
resource "aws_instance" "app_server" {
  count = var.app_count
  ami   = "ami-0866a3c8686eaeeba"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name = "shafee-jenkins-keypair"
  subnet_id = var.private_subnet[count.index % length(var.private_subnet)]
  
user_data = base64encode(
  templatefile("${path.module}/deploy.sh", {
    rds_endpoint   = split(":", var.rds_endpoint)[0],
    redis_endpoint = var.redis_endpoint,
    docker_compose = templatefile("${path.root}/../docker/docker-compose.yml", {
      rds_endpoint   = split(":", var.rds_endpoint)[0],
      redis_endpoint = var.redis_endpoint
    })
  })
)


  tags = {
    Name = "ralph_app_az${count.index + 1}"
  }

  depends_on = [
    var.mysql_db,
    var.nat_gw
  ]
}

resource "aws_instance" "bastion_host" {
  count = var.bastion_count
  ami = "ami-0866a3c8686eaeeba"                # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
                                        # Replace this with a valid AMI ID
  instance_type = var.instance_type                # Specify the desired EC2 instance size.
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name = "shafee-jenkins-keypair"                # The key pair name for SSH access to the instance.
  subnet_id = var.public_subnet[count.index % length(var.public_subnet)]
#  user_data = templatefile("kura_key_upload.sh", {
#        pub_key = local.pub_key
#   })
#   # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
   tags = {
     "Name" : "bastion_az${count.index +1}"         
   }

   depends_on = [
    var.mysql_db,
    var.nat_gw
  ]
}

# Create a security group named "tf_made_sg" that allows SSH and HTTP traffic.
# This security group will be associated with the EC2 instance created above.
resource "aws_security_group" "bastion_sg" { # in order to use securtiy group resouce, must use first "", the second "" is what terraform reconginzes as the name
  name        = "tf_made_sg"
  description = "open ssh traffic"
  vpc_id = var.vpc_id
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #  ingress {
  #   from_port   = 3000
  #   to_port     = 3000
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  #   }

    #  ingress {
    # from_port   = 80
    # to_port     = 80
    # protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    # }
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Tags for the security group
  tags = {
    "Name"      : "Bastion_SG"                          # Name tag for the security group
    "Terraform" : "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}

resource "aws_security_group" "app_sg" { # in order to use securtiy group resouce, must use first "", the second "" is what terraform reconginzes as the name
  name        = "tf_made_sg_private"
  description = "host gunicorn"
  vpc_id = var.vpc_id
  # Ingress rules: Define inbound traffic that is allowed. Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
   
   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    } 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }   

 ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    # security_groups = [var.alb_sg_id]
    }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    #   ingress {
    # from_port   = 5432
    # to_port     = 5432
    # protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    # }


    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # Tags for the security group
  tags = {
    "Name"      : "App_SG"                          # Name tag for the security group
    "Terraform" : "true"                                # Custom tag to indicate this SG was created with Terraform
    }
}

  resource "aws_security_group_rule" "backend_to_rds_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = var.rds_sg_id
}

resource "aws_security_group_rule" "allow_alb_to_app" {
  type              = "ingress"
  from_port         = var.app_port
  to_port           = var.app_port
  protocol          = "tcp"
  security_group_id = aws_security_group.app_sg.id  

  source_security_group_id = var.alb_sg_id  
}


output "instance_ip" {
 value = [for instance in aws_instance.bastion_host : instance.public_ip]  # Display the public IP address of the EC2 instance after creation.
}