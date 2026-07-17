environment          = "dev"
instance_type        = "t3.micro"
app_min_size         = 1
app_max_size         = 2
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_multi_az          = false

tenants = {
  vector-dynamics = {
    tier        = "standard"
    routing_key = "vector-dynamics"
  }
}
