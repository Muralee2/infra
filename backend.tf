terraform {
  backend "s3" {
    bucket = "strongg"
    key    = "your_tf_state_file.tfstate"
    region = "ap-south-1"
  }
}
