resource "aws_s3_bucket_policy" "manual_bucket_policy" {
  bucket = "my-tf-saniakurup-bucket"  # Replace with your actual bucket name if needed

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-tf-saniakurup-bucket",
        "arn:aws:s3:::my-tf-saniakurup-bucket/*"
      ]
    }
  ]
}
POLICY
}
