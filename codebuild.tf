resource "aws_iam_role" "build" {
  for_each = toset(var.project_envs)
  name = "${var.prefix}-${var.project_name}-${each.key}-build"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "build-admin" {
  for_each = {
    for key, value in toset(var.project_envs):
    key => upper(value)
  }
  role       = aws_iam_role.build[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


resource "aws_iam_policy" "build_codebuild" {
  for_each = toset(var.project_envs)
  name        = "${var.prefix}-${var.project_name}-${each.key}"
  description = "${var.prefix}-${var.project_name}-${each.key}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_cloudwatch_log_group.build.arn}",
                "${aws_cloudwatch_log_group.build.arn}:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.pipeline.arn}",
                "${aws_s3_bucket.pipeline.arn}/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::*"
            ],
            "Action": [
                "s3:ListBucket"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::*/env:/*"
            ],
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
              "dynamodb:GetItem",
              "dynamodb:PutItem",
              "dynamodb:DeleteItem"
            ],
            "Resource": "${aws_dynamodb_table.pipeline.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "build-codebuild" {
  for_each = toset(var.project_envs)
  role       = aws_iam_role.build[each.key].name
  policy_arn = aws_iam_policy.build_codebuild[each.key].arn
}


resource "aws_cloudwatch_log_group" "build" {
  name = "log-${var.prefix}-${var.project_name}"
}

resource "aws_cloudwatch_log_stream" "build" {
  for_each = toset(var.project_envs)
  name           = "log-${var.prefix}-${var.project_name}-${each.key}"
  log_group_name = aws_cloudwatch_log_group.build.name
}

resource "aws_codebuild_project" "build" {
  for_each = toset(var.project_envs)
  name          = "${var.prefix}-${var.project_name}-${each.key}"
  description   = "${var.prefix}-${var.project_name}-${each.key}"
  build_timeout = "240"
  service_role  = aws_iam_role.build[each.key].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "PREFIX"
      value = var.prefix
    }
    environment_variable {
      name  = "REGION"
      value = var.setup[each.key].region
    }
    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }
    environment_variable {
      name  = "ENVIRONMENT"
      value = each.key
    }
    environment_variable {
      name  = "PROJECT_GIT"
      value = var.project_git
    }
    environment_variable {
      name  = "PROJECT_PATH"
      value = var.project_path
    }
    environment_variable {
      name  = "PROJECT_TYPE"
      value = var.project_type
    }
    environment_variable {
      name  = "COMMAND"
      value = "plan"
    }
    environment_variable {
      name  = "ASSUMEROLE"
      value = "self"
    }
    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = local.tf_version[each.key]
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build.name
      stream_name = aws_cloudwatch_log_stream.build[each.key].name
    }

    s3_logs {
      status = "ENABLED"
      location = "${aws_s3_bucket.pipeline.id}/build-log-${var.prefix}-${var.project_name}-${each.key}"
    }
  }

  source {
    type            = "S3"
    location        = "${aws_s3_bucket.pipeline.id}/${aws_s3_bucket_object.pipeline.id}"
  }

  tags = {
    Environment = "${var.prefix}-${var.project_name}-${each.key}"
  }
}
 
 