resource "aws_iam_role" "pipeline" {
  name = "${var.prefix}-${var.project_name}-pipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}



resource "aws_iam_role_policy" "pipeline" {
  name = "${var.prefix}-${var.project_name}"
  role = aws_iam_role.pipeline.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.pipeline.arn}",
                "${aws_s3_bucket.pipeline.arn}/*"
            ],
            "Action": [
                "s3:*"
            ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
          ],
          "Resource": "*"
        }
  ]
}
EOF
}

resource "aws_codepipeline" "codepipeline" {
  for_each = toset(var.project_envs)
  name     = "${var.prefix}-${var.project_name}-${each.key}"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "S3"
      output_artifacts = ["source_output"]
      version  = "1"
      run_order = 1
      configuration = {
        S3Bucket = aws_s3_bucket.pipeline.id
        S3ObjectKey = aws_s3_bucket_object.pipeline.id
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      run_order = 2
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["Plan"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
        PrimarySource = "source_output"
        EnvironmentVariables = <<EOF
[{"name":"COMMAND","value":"plan","type":"PLAINTEXT"},{"name":"PREFIX","value":"${var.prefix}","type":"PLAINTEXT"},{"name":"REGION","value":"${var.setup[each.key].region}","type":"PLAINTEXT"},{"name":"ASSUMEROLE","value":"${var.setup[each.key].assume_role}","type":"PLAINTEXT"},{"name":"PROJECT_NAME","value":"${var.project_name}","type":"PLAINTEXT"},{"name":"ENVIRONMENT","value":"${each.key}","type":"PLAINTEXT"},{"name":"PROJECT_GIT","value":"${var.project_git}","type":"PLAINTEXT"},{"name":"PROJECT_PATH","value":"${var.project_path}","type":"PLAINTEXT"},{"name":"PROJECT_TYPE","value":"${var.project_type}","type":"PLAINTEXT"},{"name":"TERRAFORM_VERSION","value":"${local.tf_version[each.key]}","type":"PLAINTEXT"}]
EOF
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name             = "Approval"
      category         = "Approval"
      owner            = "AWS"
      run_order = 3
      version  = "1"
      provider        = "Manual"
    }
  }

  stage {
    name = "Apply"
    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      run_order = 4
      provider         = "CodeBuild"
      input_artifacts = ["source_output", "Plan"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
        PrimarySource = "source_output"
        EnvironmentVariables = <<EOF
[{"name":"COMMAND","value":"apply","type":"PLAINTEXT"},{"name":"PREFIX","value":"${var.prefix}","type":"PLAINTEXT"},{"name":"REGION","value":"${var.setup[each.key].region}","type":"PLAINTEXT"},{"name":"ASSUMEROLE","value":"${var.setup[each.key].assume_role}","type":"PLAINTEXT"},{"name":"PROJECT_NAME","value":"${var.project_name}","type":"PLAINTEXT"},{"name":"ENVIRONMENT","value":"${each.key}","type":"PLAINTEXT"},{"name":"PROJECT_GIT","value":"${var.project_git}","type":"PLAINTEXT"},{"name":"PROJECT_PATH","value":"${var.project_path}","type":"PLAINTEXT"},{"name":"PROJECT_TYPE","value":"${var.project_type}","type":"PLAINTEXT"},{"name":"TERRAFORM_VERSION","value":"${local.tf_version[each.key]}","type":"PLAINTEXT"}]
EOF
      }
    }
  }
}

resource "aws_codepipeline" "destroy" {
  for_each = toset(var.project_envs)
  name     = "${var.prefix}-${var.project_name}-${each.key}-destroy"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "S3"
      output_artifacts = ["source_output"]
      version  = "1"
      run_order = 1
      configuration = {
        S3Bucket = aws_s3_bucket.pipeline.id
        S3ObjectKey = aws_s3_bucket_object.pipeline.id
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Destroy"

    action {
      name             = "Destroy"
      category         = "Build"
      owner            = "AWS"
      run_order = 2
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["Plan"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
        PrimarySource = "source_output"
        EnvironmentVariables = <<EOF
[{"name":"COMMAND","value":"plan-destroy","type":"PLAINTEXT"},{"name":"PREFIX","value":"${var.prefix}","type":"PLAINTEXT"},{"name":"REGION","value":"${var.setup[each.key].region}","type":"PLAINTEXT"},{"name":"ASSUMEROLE","value":"${var.setup[each.key].assume_role}","type":"PLAINTEXT"},{"name":"PROJECT_NAME","value":"${var.project_name}","type":"PLAINTEXT"},{"name":"ENVIRONMENT","value":"${each.key}","type":"PLAINTEXT"},{"name":"PROJECT_GIT","value":"${var.project_git}","type":"PLAINTEXT"},{"name":"PROJECT_PATH","value":"${var.project_path}","type":"PLAINTEXT"},{"name":"PROJECT_TYPE","value":"${var.project_type}","type":"PLAINTEXT"},{"name":"TERRAFORM_VERSION","value":"${local.tf_version[each.key]}","type":"PLAINTEXT"}]
EOF
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name             = "Approval"
      category         = "Approval"
      owner            = "AWS"
      run_order = 3
      version  = "1"
      provider        = "Manual"
    }
  }

  stage {
    name = "ApplyDestroy"
    action {
      name            = "ApplyDestroy"
      category        = "Build"
      owner           = "AWS"
      run_order = 4
      provider         = "CodeBuild"
      input_artifacts = ["source_output", "Plan"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
        PrimarySource = "source_output"
        EnvironmentVariables = <<EOF
[{"name":"COMMAND","value":"apply-destroy","type":"PLAINTEXT"},{"name":"PREFIX","value":"${var.prefix}","type":"PLAINTEXT"},{"name":"REGION","value":"${var.setup[each.key].region}","type":"PLAINTEXT"},{"name":"ASSUMEROLE","value":"${var.setup[each.key].assume_role}","type":"PLAINTEXT"},{"name":"PROJECT_NAME","value":"${var.project_name}","type":"PLAINTEXT"},{"name":"ENVIRONMENT","value":"${each.key}","type":"PLAINTEXT"},{"name":"PROJECT_GIT","value":"${var.project_git}","type":"PLAINTEXT"},{"name":"PROJECT_PATH","value":"${var.project_path}","type":"PLAINTEXT"},{"name":"PROJECT_TYPE","value":"${var.project_type}","type":"PLAINTEXT"},{"name":"TERRAFORM_VERSION","value":"${local.tf_version[each.key]}","type":"PLAINTEXT"}]
EOF
      }
    }
  }
}

resource "aws_codepipeline" "bootstrap" {
  count      = var.project_name == "pipeline" ? 1 : 0
  name     = "${var.prefix}-${var.project_name}-update-self"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "S3"
      output_artifacts = ["source_output"]
      version  = "1"
      run_order = 1
      configuration = {
        S3Bucket = aws_s3_bucket.pipeline.id
        S3ObjectKey = aws_s3_bucket_object.pipeline.id
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Update"

    action {
      name             = "Update"
      category         = "Build"
      owner            = "AWS"
      run_order = 2
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build["default"].name
        PrimarySource = "source_output"
        EnvironmentVariables = <<EOF
[{"name":"COMMAND","value":"bootstrap","type":"PLAINTEXT"},{"name":"PREFIX","value":"${var.prefix}","type":"PLAINTEXT"},{"name":"REGION","value":"${var.setup["default"].region}","type":"PLAINTEXT"},{"name":"ASSUMEROLE","value":"${var.setup["default"].assume_role}","type":"PLAINTEXT"},{"name":"PROJECT_NAME","value":"${var.project_name}","type":"PLAINTEXT"},{"name":"ENVIRONMENT","value":"default","type":"PLAINTEXT"},{"name":"PROJECT_GIT","value":"${var.project_git}","type":"PLAINTEXT"},{"name":"PROJECT_PATH","value":"${var.project_path}","type":"PLAINTEXT"},{"name":"PROJECT_TYPE","value":"${var.project_type}","type":"PLAINTEXT"},{"name":"TERRAFORM_VERSION","value":"${local.tf_version["default"]}","type":"PLAINTEXT"}]
EOF
      }
    }
  }
}


resource "aws_codepipeline" "bootstrap-destroy" {
  count      = var.project_name == "pipeline" ? 1 : 0
  name     = "${var.prefix}-${var.project_name}-destroy-self"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "S3"
      output_artifacts = ["source_output"]
      version  = "1"
      run_order = 1
      configuration = {
        S3Bucket = aws_s3_bucket.pipeline.id
        S3ObjectKey = aws_s3_bucket_object.pipeline.id
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name             = "Approval"
      category         = "Approval"
      owner            = "AWS"
      run_order = 3
      version  = "1"
      provider        = "Manual"
    }
  }
  
  stage {
    name = "Destroy"

    action {
      name             = "Destroy"
      category         = "Build"
      owner            = "AWS"
      run_order = 2
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build["default"].name
        PrimarySource = "source_output"
        EnvironmentVariables = <<EOF
[{"name":"COMMAND","value":"bootstrap-destroy","type":"PLAINTEXT"},{"name":"PREFIX","value":"${var.prefix}","type":"PLAINTEXT"},{"name":"REGION","value":"${var.setup["default"].region}","type":"PLAINTEXT"},{"name":"ASSUMEROLE","value":"${var.setup["default"].assume_role}","type":"PLAINTEXT"},{"name":"PROJECT_NAME","value":"${var.project_name}","type":"PLAINTEXT"},{"name":"ENVIRONMENT","value":"default","type":"PLAINTEXT"},{"name":"PROJECT_GIT","value":"${var.project_git}","type":"PLAINTEXT"},{"name":"PROJECT_PATH","value":"${var.project_path}","type":"PLAINTEXT"},{"name":"PROJECT_TYPE","value":"${var.project_type}","type":"PLAINTEXT"},{"name":"TERRAFORM_VERSION","value":"${local.tf_version["default"]}","type":"PLAINTEXT"}]
EOF
      }
    }
  }
}
