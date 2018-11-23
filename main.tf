# Configure the AWS Provider
provider "aws" {
  profile = "${var.profile}"
  region  = "${var.region}"
}

#create key so you can get ssh access to the instance
resource "aws_key_pair" "sshkey" {
  key_name = "ssh-key"
  public_key = "${var.ssh_pub_key}"
}


#Create the Instance SG
resource "aws_security_group" "splunk_sg" {
  name = "splunk_sg"
}

# Allow scripts and file upload
resource "aws_security_group_rule" "in_ssh" {
  from_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.splunk_sg.id}"
  cidr_blocks = ["${var.terraform_plublic_ip}"]
  to_port = 22
  type = "ingress"
}

resource "aws_security_group_rule" "in_hec" {
  from_port = 8088
  protocol = "tcp"
  security_group_id = "${aws_security_group.splunk_sg.id}"
  cidr_blocks = ["${var.terraform_plublic_ip}"]
  to_port = 8088
  type = "ingress"
}

# Allow for apt to run and install
resource "aws_security_group_rule" "ext_any" {
  from_port = 80
  protocol = "tcp"
  security_group_id = "${aws_security_group.splunk_sg.id}"
  cidr_blocks = ["0.0.0.0/0"]
  to_port = 80
  type = "egress"
}
# Allow for splunk to get addons
resource "aws_security_group_rule" "ext_any_addon" {
  from_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.splunk_sg.id}"
  cidr_blocks = ["0.0.0.0/0"]
  to_port = 443
  type = "egress"
}

# allow web
resource "aws_security_group_rule" "lb_to_instance" {
  from_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.splunk_sg.id}"
  source_security_group_id = "${aws_security_group.splunk_lb_sg.id}"
  to_port = 443
  type = "ingress"
}

# allow HEC
resource "aws_security_group_rule" "hec_lb_to_instance" {
  from_port = 8088
  protocol = "tcp"
  security_group_id = "${aws_security_group.splunk_sg.id}"
  source_security_group_id = "${aws_security_group.splunk_hec_lb_sg.id}"
  to_port = 8088
  type = "ingress"
}

# Create the web LB SG
resource "aws_security_group" "splunk_lb_sg" {
  name = "splunk_lb_sg"

  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = [
      "${var.terraform_plublic_ip}"]
  }
  egress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    security_groups = ["${aws_security_group.splunk_sg.id}"]
  }
}

# Create the hec LB SG
resource "aws_security_group" "splunk_hec_lb_sg" {
  name = "splunk_hec_lb_sg"

  # Allows ingress from aws firehose US East (N. Virginia)
  ingress {
    protocol = "tcp"
    from_port = 8088
    to_port = 8088
    cidr_blocks = "${var.splunk_hec_sources}"
  }
  ingress {
    from_port = 8088
    protocol = "tcp"
    to_port = 8088
    cidr_blocks = ["${var.terraform_plublic_ip}"]
  }
  egress {
    protocol = "tcp"
    from_port = 8088
    to_port = 8088
    security_groups = ["${aws_security_group.splunk_sg.id}"]
  }
}

#Splunk Enterprise AMI
resource "aws_instance" "splunk_ami" {
  ami = "ami-061573a27231c6d25"
  instance_type = "c5.large"
  vpc_security_group_ids = ["${aws_security_group.splunk_sg.id}"]
  key_name = "${aws_key_pair.sshkey.key_name}"

  tags {
    Name = "splunk_ami"
  }
  provisioner "file" {
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
    source = "SplunkRPSetup.sh"
    destination = "/tmp/SplunkRPSetup.sh"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
    inline = [
      "sudo yum install httpd mod_ssl -y",
      "sudo chmod +x /tmp/SplunkRPSetup.sh",
      "sudo /tmp/SplunkRPSetup.sh"
    ]

  }
}

# Create the LB to sit infront of the splunk instance
resource "aws_elb" "splunk_hec_elb" {
  name = "splunk-hec-elb"
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c", "${var.region}d"]
  security_groups = ["${aws_security_group.splunk_hec_lb_sg.id}"]

  health_check {
    healthy_threshold = 2
    interval = 10
    target = "HTTPS:8088/services/collector/health/1.0"
    timeout = 5
    unhealthy_threshold = 2
  }

  listener {
    instance_port = 8088
    instance_protocol = "https"
    lb_port = 8088
    lb_protocol = "https"
    ssl_certificate_id = "${module.createsslcerts-hec.cert_arn}"
  }

  instances = ["${aws_instance.splunk_ami.id}"]

  tags {
    Name = "splunk-hec-elb"
  }
}

resource "aws_lb_cookie_stickiness_policy" "foo" {
  name                     = "foo-policy"
  load_balancer            = "${aws_elb.splunk_hec_elb.id}"
  lb_port                  = 8088
}


# Create the LB to sit infront of the splunk web GUI instance
resource "aws_elb" "splunk_elb" {
  name = "splunk-elb"
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c", "${var.region}d"]
  security_groups = ["${aws_security_group.splunk_lb_sg.id}"]

  listener {
    instance_port = 443
    instance_protocol = "https"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${module.createsslcerts.cert_arn}"
  }

  instances = ["${aws_instance.splunk_ami.id}"]

  tags {
    Name = "splunk-elb"
  }
}

# Call module to create Hosted Zone
module "creater53zone" {
  source = "CreateR53HostedZone"
  domain_name = "${var.domain_name}"
}

# Call module to create certificates
module "createsslcerts" {
  source = "CreateSSLCerts"
  dns_record = "${aws_elb.splunk_elb.dns_name}"
  sub_domain = "splunk"
  domain_name =  "${var.domain_name}"
  zone_id = "${module.creater53zone.zone_id}"
}

# Call module to create certificates
module "createsslcerts-hec" {
  source = "CreateSSLCerts"
  dns_record = "${aws_elb.splunk_hec_elb.dns_name}"
  sub_domain = "input-splunk"
  domain_name =  "${var.domain_name}"
  zone_id = "${module.creater53zone.zone_id}"
}