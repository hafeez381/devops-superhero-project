terraform {
  backend "s3" {
    bucket = "devops-superhero-bucket"
    key    = "terraformstate.tfstate"
    region = "us-east-1"
  }
}