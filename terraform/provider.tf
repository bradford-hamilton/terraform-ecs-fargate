# provider.tf

# Specify the provider and access details
provider "aws" {
  profile                 = "tfuser"
  region                  = var.aws_region
}

