# AWS SECURITY GROUP flow 

**Security Groups Provisioning**
This module provisions all AWS Security Groups required for the EXPENSE-DEV infrastructure.
It acts as a central networking control layer for EC2, RDS, EKS, ALB, and Bastion components.
The Security Groups are created using a custom reusable Terraform module and are orchestrated via Jenkins CI/CD.

```
Security_Group_Name	    Purpose
mysql	                  Controls access to RDS MySQL
bastion	                SSH access entry point
ingress-alb	            Internet-facing ALB access
node	                  EKS worker node communication
eks-control-plane	      EKS control plane access
```
Each Security Group:
Is created via a custom Terraform module
Allows all outbound traffic
Has strict inbound rules defined separately
---

### Ingress Rules Summary Internet → ALB

Port 443 (HTTPS) allowed from 0.0.0.0/0, Applied on Ingress ALB Security Group.
ALB → EKS Nodes, NodePort range (30000–32767) allowed.
```
Source: Ingress ALB SG
Destination: Node SG
```

* EKS Control Plane ↔ Nodes
   * All protocols allowed
   * Bidirectional communication
   * Required for Kubernetes cluster operations
---
### Bastion Access

SSH (22) allowed from internet → Bastion
```
Bastion can SSH into:
EKS nodes
Access RDS MySQL
Communicate with EKS control plane
```
---
### RDS (MySQL)
```
Port 3306 allowed from:
Bastion (manual DB access)
EKS Nodes (application access)
```
No internet exposure

---
### Jenkins Pipeline Flow

* Supported Actions
```
apply → Create Security Groups

destroy → Remove Security Groups and trigger VPC cleanup
```
* Pipeline Behavior
```
Initializes Terraform
Plans changes
Applies or destroys based on parameter
Triggers downstream jobs:
Parallel: Bastion, RDS, EKS, ECR
Sequential: ACM → ALB → CDN
```