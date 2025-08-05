terraform {
  # We want to hold off on 1.1 or higher until we have tested it.
  required_version = "~> 1.0"

  # If you use any other providers you should also pin them to the
  # major version currently being used.  This practice will help us
  # avoid unwelcome surprises.
  required_providers {
    # We have verified that our code works with version 6.7 of this
    # Terraform provider.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7"
    }
  }
}
