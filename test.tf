resource "aws_s3_bucket" "amara-publicus" {
  arn            = "arn:aws:s3:::amara-publicus"
  bucket         = "omer-publicus"
  force_destroy  = "false"
  hosted_zone_id = var.hosted_zone_id
  request_payer  = "BucketOwners"

  versioning {
    enabled    = "false"
    mfa_delete = var.mfa_enabled
  }
}
