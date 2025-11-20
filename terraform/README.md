# EKS Cluster Terraform Configuration

This Terraform configuration creates a production-ready Amazon EKS (Elastic Kubernetes Service) cluster with all best practices and standardizations.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Configuration Variables](#configuration-variables)
- [Outputs](#outputs)
- [Cost Considerations](#cost-considerations)
- [Security Best Practices](#security-best-practices)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Features

- **VPC with Public/Private Subnets**: Proper network isolation with NAT Gateways for private subnets
- **EKS Cluster**: Kubernetes cluster with encryption at rest using KMS
- **Node Groups**: Managed node groups with auto-scaling
- **EKS Add-ons**: 
  - VPC CNI (Container Network Interface)
  - CoreDNS
  - kube-proxy
  - EBS CSI Driver (for persistent volumes)
- **OIDC Provider**: For IAM Roles for Service Accounts (IRSA)
- **CloudWatch Logging**: Centralized logging for cluster control plane
- **Security Groups**: Properly configured security groups for cluster and nodes
- **Tags**: Consistent tagging for cost tracking and resource management

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. kubectl installed (for cluster access)
4. Appropriate AWS IAM permissions for EKS, VPC, EC2, IAM, KMS, CloudWatch

## Usage

### Initialize Terraform

```bash
terraform init
```

### Review the plan

```bash
terraform plan
```

### Apply the configuration

```bash
terraform apply
```

### Configure kubectl

After the cluster is created, update your kubeconfig:

```bash
aws eks update-kubeconfig --region <region> --name devops-practical-eks
```

Or use the output command:

```bash
terraform output -raw kubeconfig_command
```

### Verify cluster access

```bash
kubectl get nodes
kubectl get pods -A
```

## Configuration Variables

Key variables (with defaults):

- `aws_region`: AWS region (default: us-east-1)
- `cluster_name`: EKS cluster name (default: devops-practical-eks)
- `cluster_version`: Kubernetes version (default: 1.28)
- `node_instance_types`: Instance types for nodes (default: ["t3.medium"])
- `node_desired_size`: Desired number of nodes (default: 2)
- `node_min_size`: Minimum nodes (default: 1)
- `node_max_size`: Maximum nodes (default: 4)

See `variables.tf` for all available variables.

## Outputs

- `cluster_id`: EKS cluster ID
- `cluster_endpoint`: Cluster API endpoint
- `cluster_name`: Cluster name
- `kubeconfig_command`: Command to update kubeconfig
- `vpc_id`: VPC ID
- `private_subnet_ids`: Private subnet IDs
- `public_subnet_ids`: Public subnet IDs

## Cost Considerations

This configuration creates:
- 1 VPC with 2 public and 2 private subnets
- 2 NAT Gateways (one per AZ) - **This is the main cost driver**
- 1 EKS cluster
- Node group with 2 t3.medium instances (by default)
- EIPs for NAT Gateways
- CloudWatch log group

**Estimated monthly cost**: ~$150-200 (depending on region and usage)

To reduce costs:
- Use single NAT Gateway (modify vpc.tf)
- Use smaller instance types
- Reduce node count
- Disable CloudWatch logging

## Security Best Practices

1. **Encryption**: Secrets encrypted at rest using KMS
2. **Network Isolation**: Nodes in private subnets
3. **Security Groups**: Least privilege access
4. **IRSA**: IAM Roles for Service Accounts enabled
5. **Private Endpoint**: Cluster endpoint accessible from VPC

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will delete the EKS cluster and all associated resources. Make sure you have backups if needed.

## Troubleshooting

### Addon version conflicts

If you encounter addon version conflicts, you can:
1. Let Terraform auto-select compatible versions (current configuration)
2. Or specify exact versions by uncommenting `addon_version` in main.tf

To find compatible versions:
```bash
aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version 1.28
```

### Node group not joining

1. Check security group rules
2. Verify IAM roles have correct policies
3. Check CloudWatch logs for node group issues
4. Verify subnets have proper tags

### Access denied errors

1. Verify AWS credentials are configured
2. Check IAM permissions
3. Verify kubectl context is correct

## Additional Resources

- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

