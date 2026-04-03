resource "aws_iam_role" "crm-service-role" {
    path = "/"
    name = "crm-service-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"},{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {
        Environment = "production"
    }
}

resource "aws_iam_role" "ecs-cluster-instance-role" {
    path = "/"
    name = "ecs-cluster-instance-role"
    assume_role_policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {
        Environment = "production"
    }
}

resource "aws_iam_instance_profile" "ecs-cluster-instance-profile" {
  name = "ecs-cluster-instance-profile"
  role = aws_iam_role.ecs-cluster-instance-role.name
}


resource "aws_iam_role" "ecs_task_role" {
    path = "/"
    name = "ecs-task-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"},{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {
        Environment = "production"
    }
}

resource "aws_iam_role" "payout-recon-task-role" {
    path = "/"
    name = "payout-celery-task-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"},{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {
        Environment = "production"
    }
}

#################>>>policys<<<<<<#################
resource "aws_iam_role_policy" "ecs_policy" {
    name   = "ecs-policy"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"ecr:GetAuthorizationToken\",\"ecr:BatchCheckLayerAvailability\",\"ecr:GetDownloadUrlForLayer\",\"ecr:BatchGetImage\",\"logs:CreateLogStream\",\"logs:PutLogEvents\"],\"Effect\":\"Allow\",\"Resource\":\"*\"},{\"Action\":[\"s3:ListBucket\"],\"Effect\":\"Allow\",\"Resource\":[\"arn:aws:s3:::crm-service.${var.domain}\"]},{\"Action\":[\"s3:*Object\"],\"Effect\":\"Allow\",\"Resource\":[\"arn:aws:s3:::crm-service.${var.domain}/*\"]}]}"
    role = "ecs-task-role"
    }

resource "aws_iam_role_policy" "ecs_policy2" {
    name   = "ecs-policy"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"ecr:GetAuthorizationToken\",\"ecr:BatchCheckLayerAvailability\",\"ecr:GetDownloadUrlForLayer\",\"ecr:BatchGetImage\",\"logs:CreateLogStream\",\"logs:PutLogEvents\"],\"Effect\":\"Allow\",\"Resource\":\"*\"},{\"Action\":[\"s3:ListBucket\"],\"Effect\":\"Allow\",\"Resource\":[\"arn:aws:s3:::crm-service.${var.domain}\"]},{\"Action\":[\"s3:*Object\"],\"Effect\":\"Allow\",\"Resource\":[\"arn:aws:s3:::crm-service.${var.domain}/*\"]}]}"
    role = "payout-celery-task-role"
    }

resource "aws_iam_role_policy" "ecs_policy3" {
    name   = "ecs-policy"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"ecr:GetAuthorizationToken\",\"ecr:BatchCheckLayerAvailability\",\"ecr:GetDownloadUrlForLayer\",\"ecr:BatchGetImage\",\"logs:CreateLogStream\",\"logs:PutLogEvents\"],\"Effect\":\"Allow\",\"Resource\":\"*\"},{\"Action\":[\"s3:ListBucket\"],\"Effect\":\"Allow\",\"Resource\":[\"arn:aws:s3:::crm-service.${var.domain}\"]},{\"Action\":[\"s3:*Object\"],\"Effect\":\"Allow\",\"Resource\":[\"arn:aws:s3:::crm-service.${var.domain}/*\"]}]}"
    role = "crm-service-role"
	
    }	


resource "aws_iam_role_policy" "crm-service-role" {
	name = "crm-policy"
    policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"secretsmanager:DescribeSecret",
				"secretsmanager:GetSecretValue",
				"secretsmanager:CreateSecret",
				"secretsmanager:PutSecretValue",
				"secretsmanager:UpdateSecret",
				"secretsmanager:ListSecretVersionIds"
			],
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": [
				"secretsmanager:DeleteSecret"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:secretsmanager:ap-south-1:*:secret:business/*/api/secret/*"
		},
		{
			"Action": [
				"kms:Decrypt",
				"kms:GenerateDataKey",
				"ssm:GetParameters"
			],
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": [
				"kms:Encrypt"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:kms:ap-south-1:${var.ACCOUNT_ID}:key/${var.kms_key_id}"
		},
		{
			"Action": [
				"sqs:SendMessage"
			],
			"Effect": "Allow",
			"Resource": [
				"*"
			]
		},
		{
			"Action": [
				"s3:GetObject",
				"s3:ListObjects",
				"s3:GetObjectVersion",
				"s3:DeleteObject"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::download-center.${var.domain}/*"
		},
		{
			"Action": [
				"sqs:ListQueues"
			],
			"Effect": "Allow",
			"Resource": "*"
		}
	]
}
EOF
    role = "crm-service-role"
}

resource "aws_iam_role_policy" "ses_policy" {
	name = "ses_policy"
    policy = "{\"Statement\":[{\"Action\":[\"ses:*\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}],\"Version\":\"2012-10-17\"}"
    role = "crm-service-role"
}

resource "aws_iam_role_policy" "ses_policy2" {
	name = "ses_policy"
    policy = "{\"Statement\":[{\"Action\":[\"ses:*\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}],\"Version\":\"2012-10-17\"}"
    role = "payout-celery-task-role"
}


resource "aws_iam_role_policy" "ecs-task-policy" {
	name = "ecs-task-policy"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"secretsmanager:DescribeSecret\",\"secretsmanager:GetSecretValue\",\"secretsmanager:ListSecretVersionIds\"],\"Effect\":\"Allow\",\"Resource\":\"*\"},{\"Action\":[\"kms:Decrypt\",\"kms:GenerateDataKey\",\"ssm:GetParameters\"],\"Effect\":\"Allow\",\"Resource\":\"*\"},{\"Action\":[\"kms:Encrypt\"],\"Effect\":\"Allow\",\"Resource\":\"arn:aws:kms:ap-south-1:${var.ACCOUNT_ID}:key/${var.kms_key_id}\"},{\"Action\":[\"sqs:ReceiveMessage\",\"sqs:DeleteMessage\",\"sqs:DeleteMessageBatch\",\"sqs:ChangeMessageVisibility\",\"sqs:ChangeMessageVisibilityBatch\"],\"Effect\":\"Allow\",\"Resource\":\"arn:aws:sqs:ap-south-1:${var.ACCOUNT_ID}:payout-refund-worker-queue\"},{\"Action\":[\"sqs:ListQueues\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}]}"
    role = "ecs-task-role"
}

resource "aws_iam_role_policy" "ecs-task-policy2" {
	name = "ecs-task-policy"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"secretsmanager:DescribeSecret\",\"secretsmanager:GetSecretValue\",\"secretsmanager:ListSecretVersionIds\"],\"Effect\":\"Allow\",\"Resource\":\"*\"},{\"Action\":[\"kms:Decrypt\",\"kms:GenerateDataKey\",\"ssm:GetParameters\"],\"Effect\":\"Allow\",\"Resource\":\"*\"},{\"Action\":[\"kms:Encrypt\"],\"Effect\":\"Allow\",\"Resource\":\"arn:aws:kms:ap-south-1:${var.ACCOUNT_ID}:key/${var.kms_key_id}\"},{\"Action\":[\"sqs:ReceiveMessage\",\"sqs:DeleteMessage\",\"sqs:DeleteMessageBatch\",\"sqs:ChangeMessageVisibility\",\"sqs:ChangeMessageVisibilityBatch\"],\"Effect\":\"Allow\",\"Resource\":\"arn:aws:sqs:ap-south-1:${var.ACCOUNT_ID}:payout-refund-worker-queue\"},{\"Action\":[\"sqs:ListQueues\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}]}"
    role = "payout-celery-task-role"
}

resource "aws_iam_role_policy_attachment" "ecs-cluster-instance-role1" {
  role       = aws_iam_role.ecs-cluster-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-cluster-instance-role2" {
  role       = aws_iam_role.ecs-cluster-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"

}

resource "aws_iam_role_policy_attachment" "ecs-cluster-instance-role3" {
  role       = aws_iam_role.ecs-cluster-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  
}

resource "aws_iam_role_policy_attachment" "ecs_task_role1" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  
}
resource "aws_iam_role_policy_attachment" "ecs_task_role2" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "ecs_task_role3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  
}

resource "aws_iam_role_policy_attachment" "payout-recon-task1" {
  role       = aws_iam_role.payout-recon-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "payout-recon-task2" {
  role       = aws_iam_role.payout-recon-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  
}

resource "aws_iam_role_policy_attachment" "crm-service-role1" {
  role       = aws_iam_role.crm-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  
}
resource "aws_iam_role_policy_attachment" "crm-service-role2" {
  role       = aws_iam_role.crm-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  
}
resource "aws_iam_role_policy_attachment" "crm-service-role3" {
  role       = aws_iam_role.crm-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.s3["crm-frontend"]}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.cfd_frontend_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = var.s3["crm-frontend"]
  policy = data.aws_iam_policy_document.s3_policy.json
}


data "aws_iam_policy_document" "s3_policy_onboarding" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.s3["onboarding"]}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.cfd_onboarding_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "onboarding" {
  bucket = var.s3["onboarding"]
  policy = data.aws_iam_policy_document.s3_policy_onboarding.json
}

