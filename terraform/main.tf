provider "aws" {
    region = var.aws_region
  
}
resource "aws_security_group" "node_app_sg" {
  name = "node-app-sg"
  description = "allow ssh,http, app port"
  lifecycle {
    create_before_destroy = true
  }

ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

}
ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_instance" "node_app_server" {
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.node_app_sg.id]
    tags = {
        Name = "node-app-server"
    }
}