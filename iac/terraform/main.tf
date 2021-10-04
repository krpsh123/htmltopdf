// Creating AWS EC2 with htmtopdf application
//
// run like this:
//   export TF_VAR_htmltopdf_version=3.3.0 && terraform apply


provider "aws" {
  region = var.aws_region
}


resource "aws_security_group" "htmltopdf_SSH_HTTP" {
  name = "htmltopdf_SSH_HTTP"

  dynamic "ingress" {
    for_each = var.ingress_ports

    content {
      //description = ingress.value.description
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name    = "htmltopdf_SSH_HTTP"
    Service = "htmltopdf"
  }
}


resource "aws_instance" "htmltopdf" {
  ami               = data.aws_ami.amazon_linux2.id
  instance_type     = "t3.micro"
  availability_zone = var.availability_zone_names[0]
  key_name          = var.ssh_key_name

  security_groups = ["default", "htmltopdf_SSH_HTTP"]

  tags = {
    Name    = "htmltopdf"
    Service = "htmltopdf"
    Version = var.htmltopdf_version
  }
}
