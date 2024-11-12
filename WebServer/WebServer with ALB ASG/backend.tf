# backend.tf

terraform {
  backend "s3" {
    bucket         = "test-terraform-bucket"
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
