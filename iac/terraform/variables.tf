//---------- variables -----------------
// TF_VAR_htmltopdf_version
variable "htmltopdf_version" {}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["eu-north-1a"]
}

variable "ssh_key_name" {
  type    = string
  default = "eu-north-1"
}

variable "ingress_ports" {
  type    = list(number)
  default = [22, 80]
}


//------- data --------------------------
data "aws_ami" "amazon_linux2" {
  most_recent = true
  name_regex  = "^amzn2-ami-hvm"
  owners      = ["137112412989"] // amazon

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


//--------- output ----------
output "instance_public_ip_addr" {
  value = aws_instance.htmltopdf.public_ip
}
