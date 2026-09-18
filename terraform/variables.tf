variable "tenancy_ocid" {
  description = "OCID do tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID do usuário"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint da chave da API"
  type        = string
}

variable "private_key_path" {
  description = "Caminho local para a chave privada da API (ex: ~/.oci/oci_api_key.pem)"
  type        = string
}

variable "region" {
  description = "Região OCI (ex: sa-saopaulo-1)"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "compartment_ocid" {
  description = "OCID do compartment onde os recursos serão criados"
  type        = string
}

variable "instance_display_name" {
  description = "Nome de exibição da VM"
  type        = string
  default     = "whatsapp-insurance-agent"
}

variable "ocpus" {
  description = "Núcleos ARM (Always Free permite até 4 no total)"
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memória em GB (Always Free permite até 24 no total)"
  type        = number
  default     = 12
}

variable "ssh_public_key_path" {
  description = "Caminho local para sua chave pública SSH (ex: ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR da VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para acessar a porta 22 (restrinja ao seu IP em produção)"
  type        = string
  default     = "0.0.0.0/0"
}
