# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "frenzofunz-tfstate"    # S3 bucket name
    key            = "prod/terraform.tfstate" # path inside bucket
    region         = "ap-south-1"
    encrypt        = true
    use_lockfile = true
  }
}


# ---

# ### 📊 The Full Picture
# ```
# ┌─────────────────────────────────────────────────┐
# │                  AWS Account                     │
# │                                                  │
# │  ┌─────────────────┐    ┌──────────────────┐    │
# │  │   S3 Bucket     │    │ DynamoDB Table   │    │
# │  │                 │    │                  │    │
# │  │ prod/           │    │ LockID (key)     │    │
# │  │  terraform      │    │                  │    │
# │  │  .tfstate  ◄────┼────┼── Terraform reads│    │
# │  │                 │    │   & writes state │    │
# │  └─────────────────┘    │   lock here      │    │
# │                          └──────────────────┘    │
# └─────────────────────────────────────────────────┘
#          ▲                        ▲
#          │                        │
#          └──── GitHub Actions ────┘
#                talks to both