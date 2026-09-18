resource "oci_core_vcn" "agent_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "whatsapp-agent-vcn"
  dns_label      = "agentvcn"
}

resource "oci_core_internet_gateway" "agent_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.agent_vcn.id
  display_name   = "whatsapp-agent-igw"
  enabled        = true
}

resource "oci_core_route_table" "agent_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.agent_vcn.id
  display_name   = "whatsapp-agent-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.agent_igw.id
  }
}

resource "oci_core_security_list" "agent_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.agent_vcn.id
  display_name   = "whatsapp-agent-sl"

  # Permite que a VM faça conexões de saída.
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH - restrito ao CIDR definido em terraform.tfvars.
  ingress_security_rules {
    protocol = "6"
    source   = var.ssh_allowed_cidr

    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "agent_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.agent_vcn.id
  cidr_block                 = var.subnet_cidr
  display_name               = "whatsapp-agent-subnet"
  dns_label                  = "agentsub"
  route_table_id             = oci_core_route_table.agent_rt.id
  security_list_ids          = [oci_core_security_list.agent_sl.id]
  prohibit_public_ip_on_vnic = false
}