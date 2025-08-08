mc alias set localminio http://localhost:9000 admin changeme123
mc mb localminio/terraform-state || echo "Bucket already exists."

# Enable versioning on the terraform-state bucket
mc version enable localminio/terraform-state