output "webapp_url" {
  description = "The full URL of the deployed Azure Linux Web App"
  value       = "https://${azurerm_linux_web_app.webapp.default_hostname}"
}
output "app_service_identity_service_principal_id" {
  description = "Id of the Service principal identity of the App Service"
  value       = azurerm_linux_web_app.webapp.identity[0].principal_id
}
