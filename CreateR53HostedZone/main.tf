
# Create Hosted Zone for your domain
# inorder for this to work you have to have your domain registar point to AWS desginated NS servers
resource "aws_route53_zone" "hosted_zone" {
  name = "${var.domain_name}."
}