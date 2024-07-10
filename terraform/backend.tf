terraform {
  backend "s3" {
    bucket = "devops-superhero-bucket"
    key    = "terraforminstance.tfstate"
    region = "us-east-1"
  }
}