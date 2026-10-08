<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_object_lock_configuration.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_ownership_controls.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acl"></a> [acl](#input\_acl) | The canned ACL to apply to the bucket.  Conflicts with `grant` | `string` | `null` | no |
| <a name="input_allow_org_read_in_policy"></a> [allow\_org\_read\_in\_policy](#input\_allow\_org\_read\_in\_policy) | Whether to add a statement to allow read access for the organization to the bucket policy | `bool` | `false` | no |
| <a name="input_allow_org_write_in_policy"></a> [allow\_org\_write\_in\_policy](#input\_allow\_org\_write\_in\_policy) | Whether to add a statement to allow write access for the organization to the bucket policy | `bool` | `false` | no |
| <a name="input_block_http_in_policy"></a> [block\_http\_in\_policy](#input\_block\_http\_in\_policy) | Whether to add a statement to block HTTP requests to the bucket policy | `bool` | `true` | no |
| <a name="input_block_non_admin_writes_in_policy"></a> [block\_non\_admin\_writes\_in\_policy](#input\_block\_non\_admin\_writes\_in\_policy) | Whether to add a statement to block non-admin writes to the bucket policy | `bool` | `false` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The name of the S3 bucket to create, conflicts with `bucket_prefix` | `string` | `""` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | The prefix of the S3 bucket to create, conficts with `bucket_name` | `string` | `""` | no |
| <a name="input_enable_acl"></a> [enable\_acl](#input\_enable\_acl) | Whether to enable object lock on the bucket | `bool` | `false` | no |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | Whether to enable encryption on the bucket | `bool` | `true` | no |
| <a name="input_encryption_algorithm"></a> [encryption\_algorithm](#input\_encryption\_algorithm) | The encryption algorithm to use | `string` | `"AES256"` | no |
| <a name="input_grant"></a> [grant](#input\_grant) | An ACL policy grant. Conflicts with `acl` | `any` | `[]` | no |
| <a name="input_lifecycle_configuration"></a> [lifecycle\_configuration](#input\_lifecycle\_configuration) | whether to add a lifecycle configuration on the bucket | `bool` | `true` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | The name of a bucket to log to.  Enables S3 access logging on this bucket | `string` | `""` | no |
| <a name="input_logging_prefix"></a> [logging\_prefix](#input\_logging\_prefix) | The prefix to use for logging.  Ignored unless `logging_source` or `logging_bucket` is set | `string` | `"log/"` | no |
| <a name="input_logging_source"></a> [logging\_source](#input\_logging\_source) | The name of the bucket generating S3 access logs.  Adds a statement to bucket policy allowing logging.s3.amazonaws.com | `string` | `""` | no |
| <a name="input_object_expiry"></a> [object\_expiry](#input\_object\_expiry) | The number of days to retain objects in the bucket | `number` | `365` | no |
| <a name="input_object_lock"></a> [object\_lock](#input\_object\_lock) | Whether to enable object lock on the bucket | `bool` | `false` | no |
| <a name="input_object_lock_retention"></a> [object\_lock\_retention](#input\_object\_lock\_retention) | The number of days for objects to be locked in the bucket | `number` | `365` | no |
| <a name="input_object_old_version_expiry"></a> [object\_old\_version\_expiry](#input\_object\_old\_version\_expiry) | The number of days to retain old versions in the bucket | `number` | `30` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | The object ownership setting to use | `string` | `"BucketOwnerEnforced"` | no |
| <a name="input_ownership_controls"></a> [ownership\_controls](#input\_ownership\_controls) | Whether to enable ownership controls on the bucket | `bool` | `true` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | The policy to apply to the bucket | `string` | `""` | no |
| <a name="input_public_access_block"></a> [public\_access\_block](#input\_public\_access\_block) | Whether to block all public access to the bucket | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the bucket | `map(string)` | `{}` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Whether to enable versioning on the bucket | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output\_bucket) | n/a |
<!-- END_TF_DOCS -->
