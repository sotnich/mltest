resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "lc" {
    name      = var.project_name
    on_start = base64encode(<<SCRIPT
#!/bin/bash
set -e
sudo -u ec2-user -i <<'EOF'
aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/config/feast/feature_store.yaml /home/ec2-user/feature_store.yaml
aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/data/loan_features/table.parquet /home/ec2-user/loan_table.parquet
PACKAGE=feast[aws]
ENVIRONMENT=python3
conda activate "$ENVIRONMENT"
pip install --upgrade "$PACKAGE"
conda env config vars set FEAST_S3_BUCKET="${aws_s3_bucket.bucket.bucket}"
conda env config vars set FEAST_IAM_ROLE_ARN="${aws_iam_role.for_redshift.arn}"
conda env config vars set FEAST_REDSHIFT_CLUSTER="${aws_redshift_cluster.feast_redshift_cluster.cluster_identifier}"
conda env config vars set FEAST_REGION="${var.aws_region}"
conda deactivate
EOF
SCRIPT
    )
}

resource "aws_iam_role" "for_notebooks" {
    name = "${var.project_name}-for-notebooks"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "sagemaker.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "for_notebooks_sage_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
    role       = aws_iam_role.for_notebooks.name
}

resource "aws_iam_role_policy_attachment" "for_notebooks_s3_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    role       = aws_iam_role.for_notebooks.name
}

resource "aws_sagemaker_code_repository" "repo" {
    code_repository_name = var.project_name

    git_config {
        repository_url = "https://github.com/sotnich/mltest.git"
    }
}

resource "aws_sagemaker_notebook_instance" "ni" {
    name          = "my-notebook-instance"
    role_arn      = aws_iam_role.for_notebooks.arn
    instance_type = "ml.t2.medium"
    default_code_repository = aws_sagemaker_code_repository.repo.code_repository_name
    lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.lc.name

    tags = {
        project = var.project_name
    }
}