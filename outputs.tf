output "splunk_web_url" {
  description = "The Splunk Web URL"
  value       = "${module.createsslcerts.splunk_url}"
}
output "splunk_hec_url" {
  description = "The Splunk HEC URL"
  value       = "${module.createsslcerts-hec.splunk_url}"
}
output "splunk_password" {
  description = "Username:admin Password below for Splunk Instance"
  value = "${aws_instance.splunk_ami.id}"
}