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
