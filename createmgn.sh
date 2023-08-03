aws iam create-user --user-name mgn
aws iam create-access-key --user-name mgn
aws iam attach-user-policy --user-name mgn --policy-arn arn:aws:iam::aws:policy/AWSApplicationMigrationAgentInstallationPolicy
aws iam attach-user-policy --user-name mgn --policy-arn arn:aws:iam::aws:policy/AWSApplicationMigrationAgentPolicy
aws iam attach-user-policy --user-name mgn --policy-arn arn:aws:iam::aws:policy/service-role/AWSApplicationMigrationAgentPolicy_v2
