locals {
  bucket_prefix = substr(trim(replace(lower(var.name_prefix), "/[^a-z0-9-]/", "-"), "-"), 0, 40)
}

resource "random_id" "frontend" {
  byte_length = 4
}

resource "random_id" "images" {
  count       = var.create_images_bucket ? 1 : 0
  byte_length = 4
}

# Frontend bucket stores the React build and is only reachable through CloudFront.
resource "aws_s3_bucket" "frontend" {
  bucket        = "${local.bucket_prefix}-${random_id.frontend.hex}-frontend"
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-frontend"
  })
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Optional private media bucket is useful for book covers and upload workflows.
resource "aws_s3_bucket" "images" {
  count = var.create_images_bucket ? 1 : 0

  bucket        = "${local.bucket_prefix}-${random_id.images[0].hex}-images"
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-images"
  })
}

resource "aws_s3_bucket_versioning" "images" {
  count  = var.create_images_bucket ? 1 : 0
  bucket = aws_s3_bucket.images[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  count  = var.create_images_bucket ? 1 : 0
  bucket = aws_s3_bucket.images[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  count  = var.create_images_bucket ? 1 : 0
  bucket = aws_s3_bucket.images[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "images" {
  count  = var.create_images_bucket ? 1 : 0
  bucket = aws_s3_bucket.images[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
