terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-12w3-ns2025"
    key            = "aws-BE/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-12w3-ns2025"
    encrypt        = true
  }
}