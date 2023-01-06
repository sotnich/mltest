output "feast_ui_address" {
    description = "Feast-UI"
    value       = "${aws_instance.feast-ui-instance.public_dns}:8080"
}