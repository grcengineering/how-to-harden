# HTH Workato Control 3.01: Enable Encryption Key Management (EKM)
# Profile: L3 | NIST: SC-12, SC-28
# https://howtoharden.com/guides/workato/#31-enable-encryption-key-management-ekm

# HTH Guide Excerpt: begin terraform-kms-key
resource "aws_kms_key" "workato_ekm" {
  description             = "Workato EKM - Workspace encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKeyAdmin"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::YOUR_ACCOUNT_ID:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowWorkatoAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::WORKATO_ACCOUNT_ID:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Application = "Workato"
    Purpose     = "EKM-BYOK"
  }
}

resource "aws_kms_alias" "workato_ekm" {
  name          = "alias/workato-ekm"
  target_key_id = aws_kms_key.workato_ekm.key_id
}
# HTH Guide Excerpt: end terraform-kms-key
