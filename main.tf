provider "google-beta" {
  project = var.project
  region  = var.region
}

resource "google_project_service" "enabled-services" {
  project            = var.project
  service            = each.key
  for_each           = toset(["artifactregistry.googleapis.com", "run.googleapis.com"])
  disable_on_destroy = false

}

resource "google_cloud_run_service" "demo-webapp" {
  name     = "demo-webapp"
  location = var.region
  project  = var.project
  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = "1000"
        "autoscaling.knative.dev/min-scale" = "3"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
  depends_on = [
    google_project_service.enabled-services
  ]
}

data "google_iam_policy" "no-auth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "no-auth-policy" {
  location    = google_cloud_run_service.demo-webapp.location
  project     = google_cloud_run_service.demo-webapp.project
  service     = google_cloud_run_service.demo-webapp.name
  policy_data = data.google_iam_policy.no-auth.policy_data
}