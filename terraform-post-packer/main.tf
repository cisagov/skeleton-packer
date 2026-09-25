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

# Assign launch permissions to the ARM64 AMIs
module "ami_launch_permission_arm64" {
  for_each = local.recent_amis_arm64

  source = "github.com/cisagov/ami-launch-permission-tf-module"

  providers = {
    aws        = aws
    aws.master = aws.master
  }

  account_name_regex   = var.ami_share_account_name_regex
  ami_id               = each.value
  extraorg_account_ids = var.extraorg_account_ids
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

# Assign launch permissions to the x86-64 AMIs
module "ami_launch_permission_x86_64" {
  for_each = local.recent_amis_x86_64

  source = "github.com/cisagov/ami-launch-permission-tf-module"

  providers = {
    aws        = aws
    aws.master = aws.master
  }

  account_name_regex   = var.ami_share_account_name_regex
  ami_id               = each.value
  extraorg_account_ids = var.extraorg_account_ids
}

# This moved block allows us to rename the resources at
# module.ami_launch_permission to module.ami_launch_permission_x86_64
# instead of destroying and recreating them with a new name.
#
# TODO: Consider removing this moved block when it is no longer
# needed.  See cisagov/skeleton-packer#369 for more details.
moved {
  from = module.ami_launch_permission
  to   = module.ami_launch_permission_x86_64
}

locals {
  # Really we only want the var.recent_ami_count most recent AMIs, but
  # we have to cover the case where there are fewer than that many
  # AMIs in existence.  Hence the min()/length() tomfoolery.
  recent_amis_arm64  = toset(slice(data.aws_ami_ids.historical_amis_arm64.ids, 0, min(var.recent_ami_count, length(data.aws_ami_ids.historical_amis_arm64.ids))))
  recent_amis_x86_64 = toset(slice(data.aws_ami_ids.historical_amis_x86_64.ids, 0, min(var.recent_ami_count, length(data.aws_ami_ids.historical_amis_x86_64.ids))))
}

# Deregister any AMIs outside of local.recent_amis_x86_64 and
# local.recent_amis_x86_64, but first verify that they no longer have
# launch permissions associated with them.
resource "terraform_data" "ami_janitor" {
  for_each = setunion(setsubtract(toset(data.aws_ami_ids.historical_amis_arm64.ids), local.recent_amis_arm64), setsubtract(toset(data.aws_ami_ids.historical_amis_x86_64.ids), local.recent_amis_x86_64))

  triggers_replace = {
    # This forces the provisioner to run every time this Terraform
    # code is run.
    always_run = timestamp()
    ami_id     = each.value
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      echo "Starting AMI launch permission validation check..."

      export AWS_PROFILE=cool-images-ec2amicreate
      export AWS_REGION=us-east-1

      # Extract launch permissions
      permissions=$(aws ec2 describe-image-attribute --image-id "${self.triggers_replace.ami_id}" --attribute launchPermission --query 'LaunchPermissions[*]' --output text)

      # If no external accounts are attached, drop the AMI and its
      # snapshots in one go.
      if [ -z "$permissions" ] || [ "$permissions" == "None" ]; then
        echo "Deregistering AMI ${self.triggers_replace.ami_id} and purging backing snapshots because no launch permissions are attached."

        # Note that the AWS CLI option --delete-associated-snapshots
        # handles snapshot deletion automatically.
        aws ec2 deregister-image --image-id "${self.triggers_replace.ami_id}" --delete-associated-snapshots
      else
        echo "Skipping AMI ${self.triggers_replace.ami_id} because active launch permissions were found."
      fi
    EOT
  }
}
