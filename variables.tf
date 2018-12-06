variable "region" {
  default = "us-east-1"
}

variable "profile" {
  description = "AWS credentials profile you want to use"
}

variable "domain_name" {
  description = "Provide the TLD for your test Splunk Instance ex. \"example.com\""
}

variable "ssh_pub_key" {
  description = "Provide ssh public key"
}

variable "terraform_plublic_ip" {
  description = "Provide the public IP that terrafrom is running from and where you will be accessing the splunk web interface in CIDR notation \"1.1.1.1/32\""
}

variable "splunk_hec_sources" {
  description = "source IPs used in secuirty groups for securing the Splunk HEC LB endpoint"
  default = ["34.238.188.128/26", "34.238.188.192/26", "34.238.195.0/26", "18.216.68.160/27", "18.216.170.64/27", "18.216.170.96/27"]
}