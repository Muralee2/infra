terraform {
  backend "s3" {
    bucket = "strong4"
    key    = "your_tf_state_file.tfstate"
    region = "ap-south-1"
  }
}
