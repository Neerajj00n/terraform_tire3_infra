locals {
  s3_buckets = {
    crm-service      = "crm-service.${var.domain}"
    crm-frontend     = "crm-frontend.${var.domain}"
    download-center  = "download-center.${var.domain}"
    onboarding       = "onboarding.${var.domain}"
    logs             = "crm-service-logs-${var.project_nick_name}"
  }
}

resource "aws_s3_bucket" "buckets" {
  for_each = local.s3_buckets

  bucket = each.value
  force_destroy = true
  tags = {
    Environment = "PROD"
  }
}