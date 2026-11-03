output "app_public_ip" {
  description = "Application public IP"
  value       = module.app.public_ip
}

output "app_private_ip" {
  description = "Application private IP"
  value       = module.app.private_ip
}

output "database_private_ip" {
  description = "Database private IP"
  value       = module.database.private_ip
}

output "load_generator_public_ip" {
  description = "Load generator public IP"
  value       = module.load_generator.public_ip
}

output "load_generator_private_ip" {
  description = "Load generator private IP"
  value       = module.load_generator.private_ip
}
