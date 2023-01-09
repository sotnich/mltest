output "feast_ui_address" {
    description = "Feast-UI"
    value       = "http://${aws_instance.feast-ui-instance.public_dns}:8080"
}

output "notebooks_address" {
    description = "Notebooks-URL"
    value       = "${aws_sagemaker_notebook_instance.ni.url}/tree/mltest"
}