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