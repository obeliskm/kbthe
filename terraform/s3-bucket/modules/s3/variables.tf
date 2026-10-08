variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket to create, conflicts with `bucket_prefix`"
  default     = ""
}

variable "bucket_prefix" {
  type        = string
  description = "The prefix of the S3 bucket to create, conficts with `bucket_name`"
  default     = ""
}

variable "encryption" {
  type        = bool
  description = "Whether to enable encryption on the bucket"
  default     = true
}
variable "encryption_algorithm" {
  type        = string
  description = "The encryption algorithm to use"
  default     = "AES256" # spellr:disable-line
}

variable "lifecycle_configuration" {
  type        = bool
  description = "whether to add a lifecycle configuration on the bucket"
  default     = true
}
variable "object_expiry" {
  type        = number
  description = "The number of days to retain objects in the bucket"
  default     = 365
}

variable "object_old_version_expiry" {
  type        = number
  description = "The number of days to retain old versions in the bucket"
  default     = 30
}

variable "ownership_controls" {
  type        = bool
  description = "Whether to enable ownership controls on the bucket"
  default     = true
}
variable "object_ownership" {
  type        = string
  description = "The object ownership setting to use"
  default     = "BucketOwnerEnforced" # spellr:disable-line
}

variable "public_access_block" {
  type        = bool
  description = "Whether to block all public access to the bucket"
  default     = true
}

variable "versioning" {
  type        = bool
  description = "Whether to enable versioning on the bucket"
  default     = true
}

variable "object_lock" {
  type        = bool
  description = "Whether to enable object lock on the bucket"
  default     = false
}

variable "object_lock_retention" {
  type        = number
  description = "The number of days for objects to be locked in the bucket"
  default     = 365
}

variable "policy" {
  type        = string
  description = "The policy to apply to the bucket"
  default     = ""
}

variable "block_http_in_policy" {
  type        = bool
  description = "Whether to add a statement to block HTTP requests to the bucket policy"
  default     = true
}

variable "allow_org_read_in_policy" {
  type        = bool
  description = "Whether to add a statement to allow read access for the organization to the bucket policy"
  default     = false
}

variable "allow_org_write_in_policy" {
  type        = bool
  description = "Whether to add a statement to allow write access for the organization to the bucket policy"
  default     = false
}

variable "block_non_admin_writes_in_policy" {
  type        = bool
  description = "Whether to add a statement to block non-admin writes to the bucket policy"
  default     = false
}

# if this bucket will be the source of S3 access logs, this sets the name of the destination bucket that will receive the logs
variable "logging_bucket" {
  type        = string
  description = "The name of a bucket to log to.  Enables S3 access logging on this bucket"
  default     = ""
}
# if this bucket will receive S3 access logs, this sets the name of the source bucket that will generate the logs
variable "logging_source" {
  type        = string
  description = "The name of the bucket generating S3 access logs.  Adds a statement to bucket policy allowing logging.s3.amazonaws.com"
  default     = ""
}
# if this bucket will be the source or destination of S3 access logging, this sets the prefix to use for the logs
variable "logging_prefix" {
  type        = string
  description = "The prefix to use for logging.  Ignored unless `logging_source` or `logging_bucket` is set"
  default     = "log/"
}

variable "enable_acl" {
  type        = bool
  description = "Whether to enable object lock on the bucket"
  default     = false
}

variable "acl" {
  type        = string
  description = "The canned ACL to apply to the bucket.  Conflicts with `grant`"
  default     = null
}

variable "grant" {
  description = "An ACL policy grant. Conflicts with `acl`"
  type        = any
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the bucket"
  default     = {}
}
