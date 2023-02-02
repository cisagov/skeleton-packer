module "iam_user" {
  source = "github.com/cisagov/ami-build-iam-user-tf-module?ref=improvement%2Fsupport_build_users_with_no_ssm_needs"

  providers = {
    aws                       = aws
    aws.images-production-ami = aws.images-production-ami
    aws.images-staging-ami    = aws.images-staging-ami
    aws.images-production-ssm = aws.images-production-ssm
    aws.images-staging-ssm    = aws.images-staging-ssm
  }

  user_name = "build-skeleton-packer"
}
