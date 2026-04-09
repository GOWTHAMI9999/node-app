variable "aws_region" {
    default = "us-east-1"
  
}
variable "instance_type" {
    default = "t3.micro"
  
}
variable "key_name" {
    description = "saikey"
    default = "sai"
}
variable "ami_id" {
    description = "ubuntu 22.04 AMI"
    default = "ami-0ec10929233384c7f"
  
}