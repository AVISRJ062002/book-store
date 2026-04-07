terraform {
  backend "s3" {
    # Supply bucket, key, region, and lock settings during init:
    # terraform init \
    #   -backend-config="bucket=<state-bucket>" \
    #   -backend-config="key=terraform-bookstore/prod.tfstate" \
    #   -backend-config="region=us-east-1" \
    #   -backend-config="use_lockfile=true"
  }
}
