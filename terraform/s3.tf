# Create an S3 bucket for storing ALB logs
resource "aws_s3_bucket" "mybucket" {
    bucket        = "3tier-bucket-logs"
    force_destroy = true
}

resource "aws_s3_bucket_policy" "mybucket_policy" {
  bucket = aws_s3_bucket.mybucket.bucket

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::127311923021:root"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.mybucket.arn}/*"
    }
  ]
}
POLICY
}



/*
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.mybucket.arn}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
*/

/*


# enable server side encryption. default: aws/s3
resource "aws_s3_bucket_server_side_encryption_configuration" "encry-bucket" {
    bucket = aws_s3_bucket.mybucket.id

    rule {
        apply_server_side_encryption_by_default {
        sse_algorithm  =  "aws:kms"
        }
    }
}

# bucket ownership
resource "aws_s3_bucket_ownership_controls" "bucket-owner" {
    bucket = aws_s3_bucket.mybucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

# bucket acl, configure as private bucket
resource "aws_s3_bucket_acl" "bucket-acl" {
    bucket = aws_s3_bucket.mybucket.id
    acl    = "private"
    depends_on = [aws_s3_bucket_ownership_controls.bucket-owner]
}
'''
*/