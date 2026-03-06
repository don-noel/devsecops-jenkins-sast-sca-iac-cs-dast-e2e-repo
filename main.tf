terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" { region = "us-east-1" }

resource "aws_s3_bucket" "app_bucket" {
  bucket = "easybuggy-app-bucket"
}
resource "aws_s3_bucket_acl" "app_bucket_acl" {
  bucket = aws_s3_bucket.app_bucket.id
  acl    = "public-read"
}
resource "aws_security_group" "app_sg" {
  name = "easybuggy-sg"
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  root_block_device { encrypted = false }
}
resource "aws_db_instance" "app_db" {
  identifier              = "easybuggy-db"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "Password123!"
  skip_final_snapshot     = true
  backup_retention_period = 0
  storage_encrypted       = false
}
