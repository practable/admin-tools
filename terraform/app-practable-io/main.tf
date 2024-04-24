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

data "google_compute_image" "ubuntu_image" {
  name = "ubuntu-2004-focal-v20230715"
  #family  = "ubuntu-2004-focal-lts" 
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "ubuntu_image_ed0" {
  name = "ubuntu-2004-focal-v20230918"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "ubuntu_image_ed-dev-ui" {
  name = "ubuntu-2004-focal-v20230918"
  project = "ubuntu-os-cloud"
}

resource "google_compute_address" "static-dev" {
  name = "ipv4-address-dev"
  region = var.region
}
resource "google_compute_address" "static-ed0" {
  name = "ipv4-address-ed0"
  region = var.region
}

resource "google_compute_address" "static-ed-dev-ui" {
  name = "ipv4-address-ed-dev-ui"
  region = var.region
}

resource "google_compute_instance" "dev_vm" {
  name         = "app-practable-io-alpha-dev"
  machine_type = "e2-small"
  zone         = var.zone
  allow_stopping_for_update = true
  tags = ["http-server"]
  lifecycle {
    #create_before_destroy = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image.self_link
      size = 24
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static-dev.address
    }
  }
}

resource "google_compute_instance" "ed-dev-ui_vm" {
  name         = "app-practable-io-alpha-ed-dev-ui"
  machine_type = "e2-small"
  zone         = var.zone
  allow_stopping_for_update = true
  tags = ["http-server"]
  lifecycle {
    create_before_destroy = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image_ed-dev-ui.self_link
	  size = 18
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static-ed-dev-ui.address
    }
  }
}

resource "google_compute_instance" "ed0_vm" {
  name         = "app-practable-io-alpha-ed0"
  machine_type = "e2-standard-2"
  zone         = var.zone
  allow_stopping_for_update = true
  tags = ["http-server"]
  lifecycle {
    #create_before_destroy = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image_ed0.self_link
	  size = 24
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static-ed0.address
    }
  }
}



#https://stackoverflow.com/questions/65313133/error-invalid-instance-urls-resource-google-compute-instance-group-t-compute
resource "google_compute_instance_group" "dev" {
  name        = "instance-group-dev"
  description = "instance group for dev path"

  instances =  ["${google_compute_instance.dev_vm.self_link}"]

  lifecycle {
    create_before_destroy = true
  }
  named_port {
    name = "http"
    port = "80"
  }

  zone = var.zone
}

resource "google_compute_instance_group" "ed0" {
  name        = "instance-group-ed0"
  description = "instance group for ed0 path"

  instances =  ["${google_compute_instance.ed0_vm.self_link}"] 

  lifecycle {
    #create_before_destroy = true
  }
  named_port {
    name = "http"
    port = "80"
  }

  zone = var.zone
}

resource "google_compute_instance_group" "ed-dev-ui" {
  name        = "instance-group-ed-dev-ui"
  description = "instance group for ed-dev-ui path"

  instances =  ["${google_compute_instance.ed-dev-ui_vm.self_link}"] 

  lifecycle {
    #create_before_destroy = true
  }
  named_port {
    name = "http"
    port = "80"
  }

  zone = var.zone
}

module "mig_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 7.9"
  network = "default"
  subnetwork = "default"
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
  network = "default"
  subnetwork = "default"
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
          group = module.mig.instance_group
        }
      ]
      iap_config = {
        enable = false
      }
    }
    dev = {
      protocol    = "HTTP"
	  load_balancing_scheme = "EXTERNAL"
      port        = 80
      port_name   = "http"
	  # this sets the maximum websocket connection time to 1 year
	  # keepalives do not extend this (it seems)
      timeout_sec = 31536000
      enable_cdn  = false

      health_check = {
	    check_interval_sec = 2
		timeout_sec = 1
        request_path = "/dev/"
        port         = 80
		logging = true
      }

      log_config = {
        enable = true
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
	
    ed0 = {
      protocol    = "HTTP"
	  load_balancing_scheme = "EXTERNAL"
      port        = 80
      port_name   = "http"
	  # this sets the maximum websocket connection time to 1 year
	  # keepalives do not extend this (it seems)
      timeout_sec = 31536000
      enable_cdn  = false

      health_check = {
	    check_interval_sec = 2
		timeout_sec = 1
        request_path = "/ed0/"
        port         = 80
		logging = true
      }

      log_config = {
        enable = true
      }

      groups = [
        {
          group = google_compute_instance_group.ed0.id
        }
      ]
      iap_config = {
        enable = false
      }
    }
    ed-dev-ui = {
      protocol    = "HTTP"
	  load_balancing_scheme = "EXTERNAL"
      port        = 80
      port_name   = "http"
	  # this sets the maximum websocket connection time to 1 year
	  # keepalives do not extend this (it seems)
      timeout_sec = 31536000
      enable_cdn  = false

      health_check = {
	    check_interval_sec = 2
		timeout_sec = 1
        request_path = "/ed-dev-ui/"
        port         = 80
		logging = true
      }

      log_config = {
        enable = true
      }

      groups = [
        {
          group = google_compute_instance_group.ed-dev-ui.id
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
	
    path_rule {
      paths = [
        "/ed0",
        "/ed0/*"
      ]
      service = module.gce-lb-http.backend_services["ed0"].self_link
    }
    path_rule {
      paths = [
        "/ed-dev-ui",
        "/ed-dev-ui/*"
      ]
      service = module.gce-lb-http.backend_services["ed-dev-ui"].self_link
    }
    
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

