locals {
  # Really we only want the var.recent_ami_count most recent AMIs, but
  # we have to cover the case where there are fewer than that many
  # AMIs in existence.  Hence the min()/length() tomfoolery.
  recent_amis_arm64  = toset(slice(data.aws_ami_ids.historical_amis_arm64.ids, 0, min(var.recent_ami_count, length(data.aws_ami_ids.historical_amis_arm64.ids))))
  recent_amis_x86_64 = toset(slice(data.aws_ami_ids.historical_amis_x86_64.ids, 0, min(var.recent_ami_count, length(data.aws_ami_ids.historical_amis_x86_64.ids))))
}
