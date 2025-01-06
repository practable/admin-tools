# This staging server is usually not in use, do not remove as it is used for testing
data "google_compute_image" "ubuntu_image_ed0-staging" {
  name = "ubuntu-2404-noble-amd64-v20241219"
  project = "ubuntu-os-cloud"
}

resource "google_compute_address" "static-ed0-staging" {
  name = "ipv4-address-ed0-staging"
  region = var.region
}

resource "google_compute_instance" "ed0-staging_vm" {
  name = "app-practable-io-alpha-ed0-staging"
  machine_type = "e2-small"
  zone = var.zone
  tags = ["ed0-staging"]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image_ed0-staging.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static-ed0-staging.address
    }
  }

  service_account {
    # Google recommends custom service accounts with `cloud-platform` scope with
    # specific permissions granted via IAM Roles.
    # This approach lets you avoid embedding secret keys or user credentials
    # in your instance, image, or app code
    email  = "469911504726-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}