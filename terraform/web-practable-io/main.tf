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
  region = var.region

}

provider "google-beta" {
  project = var.project
  region = var.region
}

# comment out to update cert (also modify load balancer to not use ssl, temporarily)
resource "google_compute_ssl_certificate" "certificate-1" {
  name        = "${var.network_name}-cert"
  # create symlinks in project dir to actual key & cert
  private_key = file("${path.module}/ssl-cert.key")
  certificate = file("${path.module}/ssl-cert.pem")
}

resource "google_compute_router" "default" {
  name    = "lb-https-redirect-router"
  #network = google_compute_network.default.self_link
  network = "default"
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

resource "google_compute_firewall" "default" {
 name    = "web-firewall"
 network = "default"


 allow {
   protocol = "tcp"
   ports    = ["80"]
 }

 source_ranges = ["0.0.0.0/0"]
 target_tags = ["http-server"]
}

data "google_compute_image" "ubuntu_image_default" {
  name = "ubuntu-2204-jammy-v20240701"
  project = "ubuntu-os-cloud"
}

resource "google_compute_address" "static-default" {
  name = "ipv4-address-default"
  region = var.region
}

resource "google_compute_instance" "default_vm" {
  name         = "web-practable-io-alpha-default"
  machine_type = "e2-medium"
  zone         = var.zone
  allow_stopping_for_update = true
  tags = ["http-server"]
  lifecycle {
    create_before_destroy = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image_default.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static-default.address
    }
  }
  
  service_account {
    # Google recommends custom service accounts with `cloud-platform` scope with
    # specific permissions granted via IAM Roles.
    # This approach lets you avoid embedding secret keys or user credentials
    # in your instance, image, or app code
    email  = "484917252862-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

#https://stackoverflow.com/questions/65313133/error-invalid-instance-urls-resource-google-compute-instance-group-t-compute
resource "google_compute_instance_group" "default" {
  name        = "instance-group-default"
  description = "instance group for default path"

  instances =  ["${google_compute_instance.default_vm.self_link}"] 

  lifecycle {
    #create_before_destroy = true
  }
  named_port {
    name = "http"
    port = "80"
  }

  zone = var.zone
}




module "gce-lb-http" {
  source               = "GoogleCloudPlatform/lb-http/google"
  version           = "~> 9.0"
  name                 = "ci-https-redirect"
  project              = var.project
  target_tags          = [var.network_name]
  firewall_networks = ["default"]

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
          group = google_compute_instance_group.default.id
        }
      ]
      iap_config = {
        enable = false
      }
    }
  }
}


resource "google_compute_url_map" "urlmap" {
  name        = "urlmap"
  description = "a description"

  default_service =  module.gce-lb-http.backend_services["default"].self_link

  host_rule {
    hosts        = ["practable.dev"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name = "allpaths"
    default_service = module.gce-lb-http.backend_services["default"].self_link
       
  }
}

#https://cloud.google.com/docs/terraform/resource-management/store-state
resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name          = "${random_id.bucket_prefix.hex}-bucket-tfstate"
  force_destroy = false
  location      = "EUROPE-WEST2"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
  #encryption {
  #  default_kms_key_name = google_kms_crypto_key.terraform_state_bucket.id
  #}
  #depends_on = [
  #  google_project_iam_member.default
  #]
}

