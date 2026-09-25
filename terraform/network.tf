resource "oci_core_vcn" "dfs_way_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "dfs-way-vcn"
  dns_label      = "dfswayvcn"
}

resource "oci_core_internet_gateway" "dfs_way_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.dfs_way_vcn.id
  display_name   = "dfs-way-internet-gateway"
  enabled        = true
}

resource "oci_core_route_table" "dfs_way_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.dfs_way_vcn.id
  display_name   = "dfs-way-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.dfs_way_igw.id
  }
}

resource "oci_core_security_list" "dfs_way_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.dfs_way_vcn.id
  display_name   = "dfs-way-security-list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH
  ingress_security_rules {
    protocol = "6"
    source   = var.ssh_allowed_cidr

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "dfs_way_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.dfs_way_vcn.id
  cidr_block                 = var.subnet_cidr
  display_name               = "dfs-way-subnet"
  dns_label                  = "dfswaysub"
  route_table_id             = oci_core_route_table.dfs_way_route_table.id
  security_list_ids          = [oci_core_security_list.dfs_way_security_list.id]
  prohibit_public_ip_on_vnic = false
}

data "oci_core_vnic_attachments" "dfs_way_vnic_attachments" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.dfs_way_vm.id
}

data "oci_core_private_ips" "dfs_way_private_ips" {
  vnic_id = data.oci_core_vnic_attachments.dfs_way_vnic_attachments.vnic_attachments[0].vnic_id

  depends_on = [
    oci_core_instance.dfs_way_vm
  ]
}

resource "oci_core_public_ip" "dfs_way_public_ip" {
  compartment_id = var.compartment_ocid
  display_name   = "dfs-way-public-ip"
  lifetime       = "RESERVED"

  private_ip_id = data.oci_core_private_ips.dfs_way_private_ips.private_ips[0].id
}