output "instance_public_ip" {
  description = "IP público da VM"
  value       = oci_core_instance.agent_vm.public_ip
}

output "ssh_command" {
  description = "Comando para acessar a VM via SSH"
  value       = "ssh ubuntu@${oci_core_instance.agent_vm.public_ip}"
}

output "evolution_api_url" {
  value = "http://${oci_core_instance.agent_vm.public_ip}:8080"
}

output "n8n_url" {
  value = "http://${oci_core_instance.agent_vm.public_ip}:5678"
}
