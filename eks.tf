# --- Phase 9: EKS IAM Roles ---

# 1. IAM Role for the EKS Cluster (Control Plane)
resource "aws_iam_role" "eks_cluster_role" {
  name = "ecommerce-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 2. IAM Role for the EKS Worker Nodes (Node Group)
resource "aws_iam_role" "eks_node_role" {
  name = "ecommerce-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# --- Phase 9: EKS Cluster & Node Group ---

# 3. The EKS Cluster (Control Plane)
resource "aws_eks_cluster" "main" {
  name     = "ecommerce-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # We are placing the cluster in your existing highly-available subnets
    subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
  }

  # Ensure IAM policies are attached BEFORE creating the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# 4. The EKS Managed Node Group (Worker Nodes)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ecommerce-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]

  # EKS nodes require a bit more memory than standard web servers
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  # Ensure the cluster and IAM policies exist BEFORE creating the nodes
  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]
}