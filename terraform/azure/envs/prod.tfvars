environment    = "prod"
app_sku        = "P1v3"
db_sku         = "S3"
db_max_size_gb = 250

tenants = {
  orbitworks = {
    tier        = "standard"
    routing_key = "orbitworks"
  }
  acme-aerosystems = {
    tier        = "premium"
    routing_key = "acme-aerosystems"
  }
}
