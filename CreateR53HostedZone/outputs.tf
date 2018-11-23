# Outputs domain name servers for you to update your registrar
output "domain_nameservers" {
  description = "Name servers for you copnfigure with your domain registrar"
  value = "${aws_route53_zone.hosted_zone.name_servers}"
}
output "zone_id" {
  value = "${aws_route53_zone.hosted_zone.id}"
}