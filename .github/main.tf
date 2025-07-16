resource "aws_s3_bucket_policy" "manual_bucket_policy" {
  bucket = "my-tf-saniakurup-bucket"  # Replace with your actual bucket name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-tf-saniakurup-bucket/*"
    }
  ]
}
POLICY
}
