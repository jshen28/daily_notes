# USER TERRAFORM

Terraform is a orchestration tool which is used to create resources from predefined templates.

## COMMANDS AVAILABILE

`terraform` will print all availabile subcommands. The commonly used commands are `init`, `apply` and `destroy`. `init` is used to initialize environment and download provider plugins. `apply` is used to create all required resources; `destroy` is used to destroy recorded resources.

To initialize a environment, create a directory and put `.tf` files under it, then hit

```bash
terraform init
```

To start creating resources, hit

```bash
terraform apply [-auto-approve]

# to debug
OS_DEBUG=1 TF_LOG=DEBUG terraform apply [-auto-approve]
```

To cleanup resources, hit

```bash
terraform destroy [-auto-approve]

# to debug
OS_DEBUG=1 TF_LOG=DEBUG terraform destroy [-auto-approve]
```