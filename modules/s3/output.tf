output "logs-bucket" {
    value = aws_s3_bucket.buckets["logs"].bucket
  
}
output "crm-service-bucket" {
    value = aws_s3_bucket.buckets["crm-service"].bucket
  
}
output "crm-frontend-bucket" {
    value = aws_s3_bucket.buckets["crm-frontend"].bucket
  
}
output "download-center-bucket" {
    value = aws_s3_bucket.buckets["download-center"].bucket

}
output "onboarding-bucket" {
  value = aws_s3_bucket.buckets["onboarding"].bucket
}