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
