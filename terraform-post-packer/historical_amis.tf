# Use aws_caller_identity with the default provider (Images account)
# so we can provide the Images account ID below
data "aws_caller_identity" "images" {
}

# The IDs of all ARM64 cisagov/skeleton-packer AMIs
data "aws_ami_ids" "historical_amis_arm64" {
  owners = [data.aws_caller_identity.images.account_id]

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "name"
    values = ["example-hvm-*-arm64-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# The IDs of all x86-64 cisagov/skeleton-packer AMIs
data "aws_ami_ids" "historical_amis_x86_64" {
  owners = [data.aws_caller_identity.images.account_id]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["example-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# This moved block allows us to rename the resources at
# aws_ami_ids.historical_amis to aws_ami_ids.historical_amis_x86_64
# instead of destroying and recreating them with a new name.
#
# TODO: Consider removing this moved block when it is no longer
# needed.  See cisagov/skeleton-packer#369 for more details.
moved {
  from = aws_ami_ids.historical_amis
  to   = aws_ami_ids.historical_amis_x86_64
}
