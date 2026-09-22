output "instance_public_ip" {
  description = "IP público reservado da VM"
  value       = oci_core_public_ip.dfs_way_public_ip.ip_address
}

output "ssh_command" {
  description = "Comando para acessar a VM via SSH"
  value       = "ssh ubuntu@${oci_core_public_ip.dfs_way_public_ip.ip_address}"
}

output "evolution_api_url" {
  value = "http://${oci_core_public_ip.dfs_way_public_ip.ip_address}:8080"
}

output "n8n_url" {
  value = "http://${oci_core_public_ip.dfs_way_public_ip.ip_address}:5678"
}