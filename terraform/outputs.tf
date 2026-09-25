output "instance_public_ip" {
  description = "IP público reservado da VM DFS Way"
  value       = oci_core_public_ip.dfs_way_public_ip.ip_address
}

output "ssh_command" {
  description = "Comando para acessar a VM DFS Way via SSH"
  value       = "ssh ubuntu@${oci_core_public_ip.dfs_way_public_ip.ip_address}"
}

output "dfs_way_url" {
  description = "URL pública do DFS Way"
  value       = "https://way.dfsconsulting.com.br"
}

output "n8n_url" {
  description = "URL pública do n8n"
  value       = "https://way.dfsconsulting.com.br"
}