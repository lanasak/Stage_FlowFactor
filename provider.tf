# variable ibm_cloud_api_key {}
#  variable "region" {} 
#  variable ibm_cloud_datacenter{}

 terraform {
   required_providers {
      ibm = {
         source = "IBM-Cloud/ibm"
         version = "1.39.1"
      }
    }
  }


provider "ibm" {
  ibmcloud_api_key  = "Fylbfln8aRsrzFMGpoRJ9poh24MLLj1VVBrlscY4y7dZ"
  iaas_classic_username = "1670939_lana.sakkoul@flowfactor.be"
  iaas_classic_api_key = "1c498f440df1d2485ff5f240d821ddeef3d93c97c12fc6790d6ee239c8900b6f"
  region = "Frankfurt"
}

module "classic_openshift_single_zone_cluster" {
  source = "terraform-ibm-modules/cluster/ibm//modules/classic-openshift-single-zone"

  cluster_name                    = var.cluster_name
  worker_zone                     = var.worker_zone
  hardware                        = var.hardware
  worker_nodes_per_zone           = var.worker_nodes_per_zone
  worker_pool_flavor              = var.worker_pool_flavor
  public_vlan                     = var.public_vlan_id
  private_vlan                    = var.private_vlan_id
  master_service_public_endpoint  = var.master_service_public_endpoint
  no_subnet                       = var.no_subnet
  kube_version                    = var.kube_version
}