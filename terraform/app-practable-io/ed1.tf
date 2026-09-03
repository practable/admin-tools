# ed1 is a small, full-stack pilot instance. It runs Book, Relay, Jump,
# job-runner and PostgreSQL on one VM. The existing standalone runner instance
# is intentionally separate and unchanged.

data "google_compute_image" "ubuntu_image_ed1" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

resource "google_compute_address" "static-ed1" {
  name   = "ipv4-address-ed1"
  region = var.region
}

# A stable private address gives the existing Prometheus server a durable
# scrape target without exposing metrics through the public load balancer.
resource "google_compute_address" "internal-ed1" {
  name         = "internal-ipv4-address-ed1"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = "default"
}

resource "google_compute_disk" "ed1_postgresql_data" {
  name = "ed1-postgresql-data"
  type = "pd-balanced"
  zone = var.zone
  size = 30

  labels = {
    application = "practable"
    environment = "pilot"
    instance    = "ed1"
    purpose     = "postgresql"
  }

  lifecycle {
    # PostgreSQL contains Book's bookings and job-runner's durable execute-once
    # records. Removing this disk must require an explicit two-stage change.
    prevent_destroy = true
  }
}

resource "google_compute_resource_policy" "ed1_postgresql_snapshots" {
  name   = "ed1-postgresql-daily-snapshots"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "03:00"
      }
    }

    retention_policy {
      max_retention_days    = 14
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }

    snapshot_properties {
      guest_flush       = false
      storage_locations = [var.region]

      labels = {
        application = "practable"
        environment = "pilot"
        instance    = "ed1"
      }
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "ed1_postgresql_snapshots" {
  name = google_compute_resource_policy.ed1_postgresql_snapshots.name
  disk = google_compute_disk.ed1_postgresql_data.name
  zone = var.zone
}

resource "google_compute_instance" "ed1_vm" {
  name                      = "app-practable-io-alpha-ed1"
  machine_type              = "e2-medium"
  zone                      = var.zone
  allow_stopping_for_update = true

  labels = {
    application = "practable"
    environment = "pilot"
    instance    = "ed1"
  }

  metadata = {
    "enable-osconfig" = "TRUE"
  }

  # The load-balancer module manages access to port 80 for this tag. ed1 does
  # not use the broad, public http-server firewall tag.
  tags = ["ed1", "tf-lb-https-redirect-nat"]

  boot_disk {
    auto_delete = true

    initialize_params {
      image = data.google_compute_image.ubuntu_image_ed1.self_link
      size  = 20
      type  = "pd-balanced"
    }
  }

  # Ansible formats and mounts this disk at /var/lib/postgresql before
  # PostgreSQL is initialized. It is retained independently of the boot disk.
  attached_disk {
    source      = google_compute_disk.ed1_postgresql_data.id
    device_name = "ed1-postgresql-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = "default"
    network_ip = google_compute_address.internal-ed1.address

    access_config {
      nat_ip = google_compute_address.static-ed1.address
    }
  }

  service_account {
    email  = "469911504726-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_group" "ed1" {
  name        = "instance-group-ed1"
  description = "Instance group for the full-stack ed1 pilot"
  zone        = var.zone

  instances = [google_compute_instance.ed1_vm.self_link]

  named_port {
    name = "http"
    port = 80
  }
}

# Prometheus reaches ed1 over its private address. nginx or the individual
# services will expose only these metrics ports; none are routed by the public
# URL map.
resource "google_compute_firewall" "ed1_metrics_from_monitoring" {
  name    = "ed1-metrics-from-monitoring"
  network = "default"

  direction   = "INGRESS"
  source_tags = ["monitoring"]
  target_tags = ["ed1"]

  allow {
    protocol = "tcp"
    ports    = ["9100", "9105", "9106", "9107"]
  }
}
