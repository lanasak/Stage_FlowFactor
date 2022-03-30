variable "cluster_name" {
  default     = "openshift"
}

variable "worker_zone" {
  default     = "fra02"
}

variable "worker_pool_flavor" {
  default     ="b3c.4x16"
}


variable "public_vlan_id" {
  default     = "3201490"
}

variable "private_vlan_id" {
  default     = "3201492"
}

variable "master_service_public_endpoint" {
  default     = true
}

variable "worker_nodes_per_zone" {
  default     = 2
}


variable "no_subnet" {
  default     = false
}

variable "kube_version" {
  default     = "4.9_openshift"
}
variable "hardware" {
  default     =  "shared"
}