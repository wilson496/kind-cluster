terraform {
  backend "consul" {
    address = "http://localhost:8500"
    path    = "terraform/kind/dev" # Unique path per project/environment
    lock    = true
  }
}
