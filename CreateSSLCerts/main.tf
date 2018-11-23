# Create Cname record to points from your TLD to your instance record input
# Create Hosted Zone for your domain
# inorder for this to work you have to have your domain registar point to AWS desginated NS servers
resource "aws_route53_record" "foo" {
  zone_id = "${var.zone_id}"
  name    = "${var.sub_domain}.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.dns_record}"]
}

# Create the Certicate
resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.sub_domain}.${var.domain_name}"
  validation_method = "DNS"

   lifecycle {
    create_before_destroy = true
  }
}

# Create record to validate domain for certificate creation
resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

# Validate the certificate
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}