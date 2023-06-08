package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformBasic(t *testing.T) {
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "..",
		VarFiles: []string{"test/tf_unit_basic_test.tfvars"},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	codepipeline_ids := terraform.Output(t, terraformOptions, "codepipeline_ids")
	codebuild_ids := terraform.Output(t, terraformOptions, "codebuild_ids")
	s3_id := terraform.Output(t, terraformOptions, "s3_id")
	assert.Equal(t, "[basic-test-dev]", codepipeline_ids)
	assert.Equal(t, "[arn:aws:codebuild:eu-north-1:112659975190:project/basic-test-dev]", codebuild_ids)
	assert.Equal(t, "basic-test-112659975190", s3_id)
}
