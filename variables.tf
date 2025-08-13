variable "project_name" {
  type    = string
  default = "a-proposal-ec2-ssm"
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "allow_http_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "root_volume_size_gb" {
  type    = number
  default = 30
}
