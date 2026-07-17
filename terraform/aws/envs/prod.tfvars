environment          = "prod"
instance_type        = "t3.small"
app_min_size         = 2
app_max_size         = 6
db_instance_class    = "db.t3.medium"
db_allocated_storage = 100
db_multi_az          = true

tenants = {
  vector-dynamics = {
    tier        = "standard"
    routing_key = "vector-dynamics"
  }
  orbitworks = {
    tier        = "standard"
    routing_key = "orbitworks"
  }
}
