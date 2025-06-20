# ELIMINA el contenido anterior y reemplaza con:
output "cpu_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "status_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.status_check_failed.arn
}