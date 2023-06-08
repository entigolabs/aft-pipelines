resource "aws_dynamodb_table" "pipeline" {
  name         = "${var.prefix}-${var.project_name}-${var.project_account}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "pipeline" {
  bucket = "${var.prefix}-${var.project_name}-${var.project_account}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning"  "pipeline" {
  bucket = aws_s3_bucket.pipeline.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline" {
  bucket = aws_s3_bucket.pipeline.bucket

  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline" {
  bucket = aws_s3_bucket.pipeline.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

data "external" "pipeline" {
  program = ["${path.module}/pipeline/pipeline-zip.sh", path.root, "${var.prefix}-${var.project_name}-pipeline", path.module]
}

data "archive_file" "pipeline" {
  type        = "zip"
  source_dir = "${path.root}/${var.prefix}-${var.project_name}-pipeline"
  output_path = "${path.root}/${var.prefix}-${var.project_name}-pipeline.zip"
  depends_on = [data.external.pipeline]
}

resource "aws_s3_object" "pipeline" {
  bucket = aws_s3_bucket.pipeline.id
  key    = "pipeline.zip"
  source = "${path.root}/${var.prefix}-${var.project_name}-pipeline.zip"
  server_side_encryption = "AES256"
  etag = data.archive_file.pipeline.output_md5
  depends_on = [data.archive_file.pipeline]
}



output "s3_id" {
  value = aws_s3_bucket.pipeline.id
}

output "codepipeline_ids" {
  value = [
    for bd in aws_codepipeline.codepipeline : bd.id
  ]
}

output "codebuild_ids" {
  value = [
    for bd in aws_codebuild_project.build : bd.id
  ]
}

