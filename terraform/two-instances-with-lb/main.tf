/**
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google" {
  project = var.project
}

provider "google-beta" {
  project = var.project
}

# comment out to update cert (also modify load balancer to not use ssl, temporarily)
resource "google_compute_ssl_certificate" "certificate-1" {
  name        = "${var.network_name}-cert"
  # create symlinks in project dir to actual key & cert
  private_key = file("${path.module}/ssl-cert.key")
  certificate = file("${path.module}/ssl-cert.pem")
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.network_name
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  name    = "lb-https-redirect-router"
  network = google_compute_network.default.self_link
  region  = var.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 2.2"
  router     = google_compute_router.default.name
  project_id = var.project
  region     = var.region
  name       = "cloud-nat-lb-https-redirect"
}

data "template_file" "group-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = ""
  }
}

data "google_compute_image" "ubuntu_image" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_address" "static-dev" {
  name = "ipv4-address-dev"
  region         = "europe-west2"
}

resource "google_compute_instance" "dev_vm" {
  name         = "app-practable-io-alpha-dev"
  machine_type = "e2-small"
  zone         = "europe-west2-c"
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static-dev.address
    }
  }
}

resource "google_compute_instance_group" "dev" {
  name        = "instance-group-dev"
  description = "instance group for dev path"

  instances =  ["${google_compute_instance.dev_vm.self_link}"] #https://stackoverflow.com/questions/65313133/error-invalid-instance-urls-resource-google-compute-instance-group-t-compute
  
  named_port {
    name = "http"
    port = "80"
  }

  zone = "europe-west2-c"
}


module "mig_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 7.9"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = var.network_name
  startup_script = data.template_file.group-startup-script.rendered
  tags = [
    var.network_name,
    module.cloud-nat.router_name
  ]
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 7.9"
  instance_template = module.mig_template.self_link
  region            = var.region
  hostname          = var.network_name
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
}


resource "google_compute_backend_service" "dev" {
  name          = "backend-service-dev"
  health_checks = [google_compute_health_check.default.id]
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_health_check" "default" {
  name = "health-check"
  http_health_check {
    port = 80
	request_path       = "/dev/"
  }
}


## [START cloudloadbalancing_ext_http_gce_http_redirect]
module "gce-lb-http" {
  source               = "GoogleCloudPlatform/lb-http/google"
  version           = "~> 9.0"
  name                 = "ci-https-redirect"
  project              = var.project
  target_tags          = [var.network_name]
  firewall_networks    = [google_compute_network.default.name]
  # uncomment below when replacing ssl cert (it can't be in use)
  #ssl                  = false
  #use_ssl_certificates = false
  # uncomment below for normal operation with cert
  ssl                  = true
  ssl_certificates     = [google_compute_ssl_certificate.certificate-1.self_link]
  use_ssl_certificates = true
  https_redirect       = true

  # see https://cloud.google.com/load-balancing/docs/https/ext-http-lb-tf-module-examples
  url_map           = google_compute_url_map.urlmap.self_link
  create_url_map    = false

  backends = {
    default = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/"
        port         = 80
      }

      log_config = {
        enable = false
      }

      groups = [
        {
          group = module.mig.instance_group
        }
      ]
      iap_config = {
        enable = false
      }
    }
    dev = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/dev/"
        port         = 80
      }

      log_config = {
        enable = false
      }

      groups = [
        {
          group = google_compute_instance_group.dev.id
        }
      ]
      iap_config = {
        enable = false
      }
    }

  }
}
# [END cloudloadbalancing_ext_http_gce_http_redirect]



## TODO
## Get backend names for use in the URL map, so specify outside the load balancer?
## Figure out how to make the URL map from before ...

## investigating the terraform plan outputs shows that
## backend name(s) are "ci-https-redirect-backend-dev"

resource "google_compute_url_map" "urlmap" {
  name        = "urlmap"
  description = "a description"

  default_service =  module.gce-lb-http.backend_services["default"].self_link

  host_rule {
    hosts        = ["app.practable.io"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name = "allpaths"
    default_service = module.gce-lb-http.backend_services["default"].self_link
	
    path_rule {
      paths = [
        "/dev",
        "/dev/*"
      ]
      service = module.gce-lb-http.backend_services["dev"].self_link
    }
    
  }
}
