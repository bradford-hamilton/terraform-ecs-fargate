terraform {



  backend "s3" {
    bucket  = "hexad-terraform"
    key     = "terraform.tfstate"
    region  = "eu-central-1"
    profile = "tfuser"
  }
}
