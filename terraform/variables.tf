variable "tenancy_ocid" {
  description = "OCID da tenancy OCI"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID do compartment onde o DFS Way será criado"
  type        = string
}

variable "user_ocid" {
  description = "OCID do usuário OCI"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint da API Key OCI"
  type        = string
}

variable "private_key_path" {
  description = "Caminho da chave privada da API OCI"
  type        = string
}

variable "region" {
  description = "Região OCI"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "ssh_public_key_path" {
  description = "Caminho da chave pública SSH usada na VM"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorizado a acessar SSH"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR da VCN do DFS Way"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR da subnet do DFS Way"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_display_name" {
  description = "Nome da VM DFS Way"
  type        = string
  default     = "dfs-way"
}

variable "ocpus" {
  description = "Quantidade de OCPUs"
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memória da VM em GB"
  type        = number
  default     = 12
}