resource "aws_s3_bucket" "bucket" {
    bucket        = var.project_name
    force_destroy = true
}

resource "aws_s3_object" "zipcode_features_file_upload" {
    bucket = aws_s3_bucket.bucket.bucket
    key    = "data/zipcode_features/table.parquet"
    source = "../data/zipcode_table.parquet"
}

resource "aws_s3_object" "credit_history_file_upload" {
    bucket = aws_s3_bucket.bucket.bucket
    key    = "data/credit_history/table.parquet"
    source = "../data/credit_history.parquet"
}

resource "aws_s3_object" "loan_features_file_upload" {
    bucket = aws_s3_bucket.bucket.bucket
    key    = "data/loan_features/table.parquet"
    source = "../data/loan_table.parquet"
}

resource "aws_s3_object" "feast_feature_store_file_upload" {
    bucket = aws_s3_bucket.bucket.bucket
    key    = "config/feast/feature_store.yaml"
    source = "../featurestore/feast/repo/feature_store.yaml"
}

resource "aws_s3_object" "feast_features_py_file_upload" {
    bucket = aws_s3_bucket.bucket.bucket
    key    = "config/feast/features.py"
    source = "../featurestore/feast/repo/features.py"
}

resource "aws_s3_object" "feastui_service_file_upload" {
    bucket = aws_s3_bucket.bucket.bucket
    key    = "config/feast/feastui.service"
    source = "../featurestore/feast/feastui.service"
}