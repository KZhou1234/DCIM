 variable region{
 }     

 variable instance_type{
 }  

 variable "vpc_id"{
 }

 variable "public_subnet"{
 }

 variable "private_subnet"{
 }

 variable "bastion_count"{
 }

 variable "app_count"{
 }

 variable "db_name"{
 }

 variable "db_username"{
 }

 variable "db_password"{
 }

 variable "rds_address"{
 }

 variable "rds_endpoint"{
 }
variable "redis_endpoint" {
  description = "Endpoint for the Redis cache"
  type        = string
}
 variable "mysql_db"{
 }

variable "rds_sg_id" {
 }
 
variable "alb_sg_id"{
}

variable "app_port"{
}

variable "dockerhub_user"{
}

variable "dockerhub_pass"{
}

variable "nat_gw"{
}
# variable "alb_dns_name" {
  
# }