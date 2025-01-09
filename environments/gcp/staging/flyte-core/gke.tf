locals {
  gke_subnetwork          = module.network.subnets_names[0]
  gke_pods_range_name     = module.network.subnets_secondary_ranges[0][0].range_name
  gke_services_range_name = module.network.subnets_secondary_ranges[0][1].range_name
}

module "gke" {
  source                   = "terraform-google-modules/kubernetes-engine/google"
  project_id               = local.project_id
  region                   = local.region
  name                     = local.name_prefix
  regional                 = true
  release_channel          = "STABLE"
  network                  = module.network.network_name
  subnetwork               = local.gke_subnetwork
  ip_range_pods            = local.gke_pods_range_name
  ip_range_services        = local.gke_services_range_name
  create_service_account   = true
  identity_namespace       = "enabled"
  remove_default_node_pool = true

  node_pools = [
    {
      name               = "default-spot"
      machine_type      = "e2-standard-8"
      disk_size_gb      = 100
      enable_gcfs       = true
    },
    {
      name              = "default-gpu"
      machine_type      = "g2-standard-4"
      disk_size_gb      = 100
      enable_gcfs       = true
      disk_type         = "pd-ssd"
    },
    {
      name              = "default"
      machine_type      = "e2-standard-2"
      disk_size_gb      = 100
      node_locations    = "asia-south1-a"
      location_policy   = "ANY"
      initial_node_count = 1
      total_min_count   = 0
      total_max_count   = 1
      enable_gcfs       = true
    }
  ]

  node_pools_taints = {
    all = []

    default-spot = [
      {
        key    = "cloud.google.com/gke-spot"
        value  = true
        effect = "NO_SCHEDULE"
      },
    ]

    default-gpu = [
      {
        key    = "nvidia.com/gpu"
        value  = "present"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  depends_on = [google_project_service.project ]
}

output gke_cluster_name {
  value = module.gke.name

}