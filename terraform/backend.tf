terraform {
  backend "s3" {
    bucket = "devops-superhero-bucket"
    key    = "terraform/state"
    region = "us-east-1"
  }
}