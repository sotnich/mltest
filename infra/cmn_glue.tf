resource "aws_glue_catalog_database" "feature_database" {
    name = "${var.project_name}-db"
}

resource "aws_glue_catalog_table" "zipcode_features_table" {
    name          = "zipcode_features"
    database_name = aws_glue_catalog_database.feature_database.name

    table_type = "EXTERNAL_TABLE"

    parameters = {
        EXTERNAL              = "TRUE"
        "parquet.compression" = "SNAPPY"
    }

    storage_descriptor {
        location      = "s3://${aws_s3_bucket.bucket.bucket}/data/zipcode_features/"
        input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

        ser_de_info {
            name                  = "my-stream"
            serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

            parameters = {
                "serialization.format" = 1
            }
        }

        columns {
            name = "zipcode"
            type = "bigint"
        }

        columns {
            name = "city"
            type = "string"
        }
        columns {
            name = "state"
            type = "string"
        }
        columns {
            name = "location_type"
            type = "string"
        }
        columns {
            name = "tax_returns_filed"
            type = "bigint"
        }
        columns {
            name = "population"
            type = "bigint"
        }
        columns {
            name = "total_wages"
            type = "bigint"
        }
        columns {
            name = "event_timestamp"
            type = "timestamp"
        }
        columns {
            name = "created_timestamp"
            type = "timestamp"
        }
    }
}

resource "aws_glue_catalog_table" "credit_history_table" {
    name          = "credit_history"
    database_name = aws_glue_catalog_database.feature_database.name

    table_type = "EXTERNAL_TABLE"

    parameters = {
        EXTERNAL              = "TRUE"
        "parquet.compression" = "SNAPPY"
    }

    storage_descriptor {
        location      = "s3://${aws_s3_bucket.bucket.bucket}/data/credit_history/"
        input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

        ser_de_info {
            name                  = "my-stream"
            serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

            parameters = {
                "serialization.format" = 1
            }
        }
        columns {
            name = "dob_ssn"
            type = "string"
        }

        columns {
            name = "credit_card_due"
            type = "bigint"
        }
        columns {
            name = "mortgage_due"
            type = "bigint"
        }
        columns {
            name = "student_loan_due"
            type = "bigint"
        }
        columns {
            name = "vehicle_loan_due"
            type = "bigint"
        }
        columns {
            name = "hard_pulls"
            type = "bigint"
        }
        columns {
            name = "missed_payments_2y"
            type = "bigint"
        }
        columns {
            name = "missed_payments_1y"
            type = "bigint"
        }
        columns {
            name = "missed_payments_6m"
            type = "bigint"
        }
        columns {
            name = "bankruptcies"
            type = "bigint"
        }
        columns {
            name = "event_timestamp"
            type = "timestamp"
        }
        columns {
            name = "created_timestamp"
            type = "timestamp"
        }
    }
}