# AWS Splunk Instance
<b>Creates a test splunk instance in AWS</b>

<b>Details:</b>

- Uses the current (static set) Splunk Enterprise AMI
- Creates the instance in the default VPC
- Creates a hosted R53 Zone for dns and cert mgmt
- Creates 2 classic LB's (one for Web interface, one for HEC interface)
- Uses provided shell script to install and configure apache reverse proxy (work around for ssl offload SPL-79993)
- Creates valid Certs for both interfaces (required for HEC to work)

<b>Inputs:</b>

 - variable "region" {
    default = "us-east-1"
  }

 - variable "profile" {
    description = "AWS credentials profile you want to use"
  }

 - variable "domain_name" {
    description = "Provide the TLD for your test Splunk Instance ex. \"example.com\""
  }

 - variable "ssh_pub_key" {
    description = "Provide ssh public key"
  }

 - variable "terraform_plublic_ip" {
    description = "Provide the public IP that terrafrom is running from and where you will be accessing the splunk web interface in CIDR notation \"1.1.1.1/32\""
  }

 - variable "splunk_hec_sources" {
  description = "source IPs used in secuirty groups for securing the Splunk HEC LB endpoint"
  default = ["34.238.188.128/26", "34.238.188.192/26", "34.238.195.0/26"]
}

<b>Directions:</b>
- The current default security group (variable "splunk_hec_sources") for the HEC LB endpoint is for aws firehose in us-east-1. update as needed
- Run the terraform code
- While its running you must update your domain registrar with the name servers provided with your new R53 hosted zone. I used a free temp domain (ex freenom). You will have to be logged into the AWS console to get the Name Servers. If you didnt update your Name Servers in time the code will fail but after doing so rerun the terraform code
- Log into splunk web interface as username is "admin" and terraform will ouput the password (ami instance id)
- provide a license (restart)
- enable HEC if needed 


