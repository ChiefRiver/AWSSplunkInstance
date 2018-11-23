output "cert_arn" {
  description = "The arn for the cert created"
  value       = "${aws_acm_certificate.cert.arn}"
}

output "splunk_url" {
  value = "${aws_route53_record.foo.fqdn}"
}
