# module to create an S3 bucket with common MP knobs

locals {
  # If the inputs to this module include any of
  # - a bucket policy
  # - the name of a bucket sending S3 access logs to this bucket
  # - boolean for read or write access for the organization set to true
  # - boolean to block non-admin writes set to true
  # - boolean to block HTTP requests set to true (the default)
  # then this module will manage the bucket policy - almost always, as there are few reasons to allow HTTP support
  # NOTE! 'manage' in this context means the module will overwrite any existing bucket policy without warning - if another
  # module is also managing the bucket policy, the two processes will fight
  manage_policy = var.policy != "" || var.logging_source != "" || var.allow_org_read_in_policy || var.allow_org_write_in_policy || var.block_http_in_policy

  # if bucket_name is provided, create a Name: tag and merge it with any supplied var.tags, otherwise bucket_prefix
  # was supplied and we don't know what the name of the bucket is, so don't attempt to set a Name tag - use the supplied tags
  # (if any) as is.  This will then be merged with the provider Tags in the bucket resource.
  tags = var.bucket_name != "" ? merge(var.tags, { Name = var.bucket_name }) : var.tags
}

data "aws_caller_identity" "current" {}

# only do the organization lookup if allow_org_read_in_policy or allow_org_write_in_policy is true - otherwise this data source is not required
data "aws_organizations_organization" "org" {
  count = var.allow_org_read_in_policy || var.allow_org_write_in_policy ? 1 : 0
}

# override the the statements generated here with the supplied policy (if any) - if the supplied policy is empty (the default)
# then no override happens and the policy is just whichever dynamic statements are in effect.  If the policy supplied by the
# calling module does not contain a statement with a sid that matches an in-effect dynamic statement, (eg "BlockHTTPRequests"),
# then the in-effect dynamic statements are prefixed onto the supplied policy.

# In the unlikely event that the calling module needs to allow non-HTTPS requests to the bucket, it can supply a policy with a
# statement with a sid of "BlockHTTPRequests", or set var.block_http_in_policy to false.
data "aws_iam_policy_document" "bucket_policy" {

  override_policy_documents = [var.policy]

  dynamic "statement" {
    for_each = var.block_http_in_policy ? [1] : []
    content {
      sid     = "BlockHTTPRequests"
      effect  = "Deny"
      actions = ["s3:*"]
      resources = [
        aws_s3_bucket.self.arn,
        "${aws_s3_bucket.self.arn}/*"
      ]
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }

  # deny write requests from non-admin principals
  dynamic "statement" {
    for_each = var.block_non_admin_writes_in_policy ? [1] : []
    content {
      sid     = "BlockNonAdminWrites"
      effect  = "Deny"
      actions = ["s3:Put*"]
      resources = [
        aws_s3_bucket.self.arn,
        "${aws_s3_bucket.self.arn}/*"
      ]
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      condition {
        test     = "ArnNotLike"
        variable = "aws:PrincipalARN"
        values = [
          "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/ap-southeast-2/AWSReservedSSO_FullAccess_*",
        ]
      }
    }
  }

  # allow the source bucket to write access logs to this bucket
  dynamic "statement" {
    for_each = var.logging_source != "" ? [1] : []
    content {
      sid       = "AllowS3AccessLogging"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.self.arn}/${var.logging_prefix}*"]
      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }
      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = ["arn:aws:s3:::${var.logging_source}"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }

  # allow every account in the org to read objects in this bucket
  dynamic "statement" {
    for_each = var.allow_org_read_in_policy ? [1] : []
    content {
      sid = "AllowOrgReadAccess"
      actions = [
        "s3:GetBucketVersioning",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket",
      ]
      resources = [
        aws_s3_bucket.self.arn,
        "${aws_s3_bucket.self.arn}/*"
      ]
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [data.aws_organizations_organization.org[0].id]
      }
    }
  }

  # allow every account in the org to write objects in this bucket
  dynamic "statement" {
    for_each = var.allow_org_write_in_policy ? [1] : []
    content {
      sid = "AllowOrgWriteAccess"
      actions = [
        "s3:GetBucketVersioning",
        "s3:ListBucket",
        "s3:*Object*",
      ]
      resources = [
        aws_s3_bucket.self.arn,
        "${aws_s3_bucket.self.arn}/*"
      ]
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [data.aws_organizations_organization.org[0].id]
      }
    }
  }
}

# trivy:ignore:AVD-AWS-0090 - versioning may or may not be enabled below, this stops trivy complaining either way
resource "aws_s3_bucket" "self" {
  bucket = var.bucket_name == "" ? null : var.bucket_name

  bucket_prefix = var.bucket_prefix == "" ? null : var.bucket_prefix

  object_lock_enabled = var.object_lock ? true : null

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "self" {
  count  = var.versioning ? 1 : 0
  bucket = aws_s3_bucket.self.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "self" {
  count  = var.encryption ? 1 : 0
  bucket = aws_s3_bucket.self.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.encryption_algorithm
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "self" {
  count  = var.ownership_controls ? 1 : 0
  bucket = aws_s3_bucket.self.id
  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "self" {
  count  = var.public_access_block ? 1 : 0
  bucket = aws_s3_bucket.self.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "self" {
  count  = var.lifecycle_configuration ? 1 : 0
  bucket = aws_s3_bucket.self.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    filter { prefix = "" }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.object_old_version_expiry
    }
    expiration {
      days = var.object_expiry
    }
    noncurrent_version_expiration {
      noncurrent_days = var.object_old_version_expiry
    }
  }

  rule {
    id     = "cleanup-deletemarkers"
    status = "Enabled"

    filter { prefix = "" }

    expiration {
      expired_object_delete_marker = true
    }
  }

  # if object_expiry is greater than 120 days, then transition to STANDARD_IA after 90 days (standard-IA is billed for minimum 30 days storage)
  # note that this honours the minimum object size, so objects smaller than 128KiB will not be transitioned
  dynamic "rule" {
    for_each = var.object_expiry > 120 ? [1] : []
    content {
      id     = "transitiontostandard-ia"
      status = "Enabled"

      filter { prefix = "" }

      transition {
        days          = 90
        storage_class = "STANDARD_IA"
      }
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "self" {
  count  = var.object_lock ? 1 : 0
  bucket = aws_s3_bucket.self.id

  rule {
    default_retention {
      days = var.object_lock_retention
      mode = "COMPLIANCE"
    }
  }
}

resource "aws_s3_bucket_policy" "self" {
  count  = local.manage_policy ? 1 : 0
  bucket = aws_s3_bucket.self.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_logging" "self" {
  count         = var.logging_bucket != "" ? 1 : 0
  bucket        = aws_s3_bucket.self.id
  target_bucket = var.logging_bucket
  target_prefix = var.logging_prefix
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket_acl" "self" {
  count  = var.enable_acl ? 1 : 0
  bucket = aws_s3_bucket.self.id

  acl = var.acl

  dynamic "access_control_policy" {
    for_each = length(var.grant) > 0 ? [true] : []

    content {
      dynamic "grant" {
        for_each = var.grant

        content {
          permission = grant.value.permission

          grantee {
            type          = grant.value.type
            id            = try(grant.value.id, null)
            uri           = try(grant.value.uri, null)
            email_address = try(grant.value.email, null)
          }
        }
      }

      owner {
        id = data.aws_canonical_user_id.current.id
      }
    }
  }

  # This `depends_on` is to prevent "AccessControlListNotSupported: The bucket does not allow ACLs."
  depends_on = [aws_s3_bucket_ownership_controls.self]
}

# fix up inconsistent naming of the bucket ACL resource
# this can be removed when all calls to this module that manage ACL's are at 8.11.5 or later
moved {
  from = aws_s3_bucket_acl.this[0]
  to   = aws_s3_bucket_acl.self[0]
}
