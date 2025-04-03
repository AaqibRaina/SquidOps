locals{
  prefix = var.project != "" ? "${var.project}-" : ""
}
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "${local.prefix}terraform-state-lock-${var.region}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.1"
  bucket  = "${local.prefix}terraform-squids-state-bucket-${var.region}"

  tags = {
    Terraform   = "true"
  }
}
