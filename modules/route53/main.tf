
resource "aws_route53_zone" "private_zone" {
  name = var.domain
  vpc {
    vpc_id = var.vpc_id
  }
  
}

resource "aws_route53_zone" "public_zone" {
  name = var.domain
}


# data "aws_route53_zone" "public_zone" {
#   name         = var.domain
#   private_zone = false
# }


resource "aws_route53_record" "apis_subdomain" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "apis.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.ecs_internal_alb_dns_name]  # Replace with the desired DNS IP
}

resource "aws_route53_record" "subdomain2" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "error-reports.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.ecs_internal_alb_dns_name]  # Replace with the desired DNS IP
}


resource "aws_route53_record" "apis_subdomain_public" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "apis.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.ecs_alb_dns_name] # Replace with the desired DNS IP
}

resource "aws_route53_record" "subdomain2_public" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "error-reports.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.ecs_alb_dns_name] # Replace with the desired DNS IP
}

########################################################
#LOG GROUP
resource "aws_cloudwatch_log_group" "LogsLogGroup" {
    name = "celery-worker-task-log-group"
    retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "LogsLogGroup2" {
    name = "payout-refund-worker-log-group"
    retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "LogsLogGroup3" {
    name = "payout-status-enquiry-worker-log-group"
    retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "LogsLogGroup4" {
    name = "webhook-worker-log-group"
    retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "LogsLogGroup5" {
    name = "crm-ecs-log-group"
}

####################################################




# ── Certificate for CloudFront (MUST be us-east-1) ──
resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us_east_1         # CloudFront only accepts us-east-1
  domain_name       = var.domain
  subject_alternative_names = ["*.${var.domain}"] # covers www, api, etc.
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ── Certificate for ALB (your region, e.g. ap-south-1) ──
resource "aws_acm_certificate" "alb_cert" {
  domain_name       = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}



# ── Validation records for CloudFront cert ──
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ── Validation records for ALB cert ──
resource "aws_route53_record" "alb_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ── Wait for validation to complete ──
resource "aws_acm_certificate_validation" "cloudfront_cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "alb_cert" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_cert_validation : record.fqdn]
}
