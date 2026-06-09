# Inspection Phases — Command Catalog

Full per-phase read-only command catalog for the AWS account inspection skill.
Read this when you reach the enumeration step. Every command uses `--profile $PROFILE`
and `--output json | jq` per the safety contract in SKILL.md.

## Table of contents

- [Phase 1: Identity & Account Context](#phase-1-identity--account-context) — mandatory
- [Phase 2: Networking](#phase-2-networking)
- [Phase 3: Compute](#phase-3-compute)
- [Phase 4: Storage](#phase-4-storage)
- [Phase 5: Databases](#phase-5-databases)
- [Phase 6: DNS & Discovery](#phase-6-dns--discovery)
- [Phase 7: Security & Governance](#phase-7-security--governance) — mandatory
- [Phase 8: Monitoring](#phase-8-monitoring)
- [Phase 9: Messaging & Integration](#phase-9-messaging--integration)
- [Phase 10: Container Registry](#phase-10-container-registry)
- [Phase 11: SSM](#phase-11-ssm)
- [Phase 12: Cost & Tagging](#phase-12-cost--tagging)
- [Error handling](#error-handling)
- [Output format](#output-format)
- [Post-inspection checklist](#post-inspection-checklist)

Execute 1–12 in order. After each, evaluate the **skip condition** for the next.
Phase 13 (Well-Architected) is in SKILL.md — it needs no commands.

---

## Phase 1: Identity & Account Context

**Mandatory.**

```bash
aws sts get-caller-identity --profile $PROFILE --output json
aws iam list-account-aliases --profile $PROFILE --output json
aws ec2 describe-regions --profile $PROFILE --region $REGION --output json \
  | jq '[.Regions[] | select(.OptInStatus != "not-opted-in")] | length'
aws ec2 describe-availability-zones --profile $PROFILE --region $REGION --output table
aws iam get-account-summary --profile $PROFILE --output json | jq '.SummaryMap'
```

Capture: Account Name, ID, Profile, Role, Region, Enabled Regions, AZs, IAM Users,
IAM Roles, IAM Policies (customer).

---

## Phase 2: Networking

**Skip if VPC count = 0.**

```bash
aws ec2 describe-vpcs --profile $PROFILE --region $REGION --output json \
  | jq '.Vpcs[] | {VpcId, CidrBlock, Name: (.Tags[]? | select(.Key=="Name") | .Value), State, IsDefault}'
aws ec2 describe-subnets --profile $PROFILE --region $REGION --output json \
  | jq '.Subnets[] | {SubnetId, CidrBlock, AvailabilityZone, Name: (.Tags[]? | select(.Key=="Name") | .Value), AvailableIpAddressCount}'
aws ec2 describe-route-tables --profile $PROFILE --region $REGION --output json \
  | jq '.RouteTables[] | {RouteTableId, Name: (.Tags[]? | select(.Key=="Name") | .Value), Routes: [.Routes[] | {Destination: .DestinationCidrBlock, Target: (.GatewayId // .TransitGatewayId // .NatGatewayId // .VpcPeeringConnectionId // "local")}]}'
aws ec2 describe-internet-gateways --profile $PROFILE --region $REGION --output json \
  | jq '.InternetGateways[] | {InternetGatewayId, VpcId: .Attachments[0].VpcId}'
aws ec2 describe-nat-gateways --profile $PROFILE --region $REGION --output json \
  | jq '.NatGateways[] | {NatGatewayId, State, SubnetId, Name: (.Tags[]? | select(.Key=="Name") | .Value)}'
aws ec2 describe-transit-gateways --profile $PROFILE --region $REGION --output json \
  | jq '.TransitGateways[] | {TransitGatewayId, State, Description}'
aws ec2 describe-transit-gateway-attachments --profile $PROFILE --region $REGION --output json \
  | jq '.TransitGatewayAttachments[] | {TransitGatewayId, ResourceId, ResourceType, State}'
aws ec2 describe-vpn-gateways --profile $PROFILE --region $REGION --output json \
  | jq '.VpnGateways[] | {VpnGatewayId, State, Type, VpcAttachments: [.VpcAttachments[] | .VpcId]}'
aws ec2 describe-vpn-connections --profile $PROFILE --region $REGION --output json \
  | jq '.VpnConnections[] | {VpnConnectionId, State, Type, VpnGatewayId, CustomerGatewayId}'
aws ec2 describe-vpc-endpoints --profile $PROFILE --region $REGION --output json \
  | jq '.VpcEndpoints[] | {VpcEndpointId, ServiceName, VpcId, State, PrivateDnsEnabled}'
aws ec2 describe-security-groups --profile $PROFILE --region $REGION --output json \
  | jq '.SecurityGroups[] | {GroupId, GroupName, VpcId, Description}'
aws ec2 describe-network-acls --profile $PROFILE --region $REGION --output json \
  | jq '.NetworkAcls[] | {NetworkAclId, VpcId, IsDefault}'
aws ec2 describe-flow-logs --profile $PROFILE --region $REGION --output json \
  | jq '.FlowLogs[] | {FlowLogId, ResourceId, TrafficType, LogGroupName, State}'
aws ec2 describe-addresses --profile $PROFILE --region $REGION --output json \
  | jq '.Addresses[] | {PublicIp, AllocationId, AssociationId, InstanceId, NetworkInterfaceId}'
```

TF: `aws_vpc` `vpc-xxx`, `aws_subnet` `subnet-xxx`, `aws_route_table` `rtb-xxx`,
`aws_internet_gateway` `igw-xxx`, `aws_nat_gateway` `nat-xxx`,
`aws_ec2_transit_gateway` `tgw-xxx`, `aws_vpn_connection` `vpn-xxx`,
`aws_vpc_endpoint` `vpce-xxx`, `aws_security_group` `sg-xxx`, `aws_eip` `eipalloc-xxx`.

---

## Phase 3: Compute

**Skip if EC2=0, Lambda=0, ECS=0, EKS=0.**

```bash
aws ec2 describe-instances --profile $PROFILE --region $REGION --output json \
  | jq '[.Reservations[] | .Instances[] | {InstanceId, InstanceType, State: .State.Name, Name: (.Tags[]? | select(.Key=="Name") | .Value), SubnetId, SecurityGroups: [.SecurityGroups[] | .GroupId]}]'
aws ec2 describe-volumes --profile $PROFILE --region $REGION --output json \
  | jq '.Volumes[] | {VolumeId, Size, State, VolumeType, Encrypted, Attachments: [.Attachments[] | {InstanceId, Device}]}'
aws ec2 describe-snapshots --owner-ids self --profile $PROFILE --region $REGION --output json \
  | jq '.Snapshots[] | {SnapshotId, VolumeSize, StartTime, Description}'
aws ec2 describe-key-pairs --profile $PROFILE --region $REGION --output json \
  | jq '.KeyPairs[] | {KeyName, KeyType}'
aws ec2 describe-launch-templates --profile $PROFILE --region $REGION --output json \
  | jq '.LaunchTemplates[] | {LaunchTemplateId, LaunchTemplateName, LatestVersionNumber}'
aws lambda list-functions --profile $PROFILE --region $REGION --output json \
  | jq '.Functions[] | {FunctionName, Runtime, MemorySize, Timeout, Handler, VpcConfig: (if .VpcConfig.VpcId then {VpcId, SubnetIds: .VpcConfig.SubnetIds, SecurityGroupIds: .VpcConfig.SecurityGroupIds} else "non-VPC" end)}'
aws lambda list-layers --profile $PROFILE --region $REGION --output json \
  | jq '.Layers[] | {LayerName, LatestMatchingVersion: .LatestMatchingVersion.Version}'
aws ecs list-clusters --profile $PROFILE --region $REGION --output json | jq '.clusterArns | length'
# If clusters > 0:
aws ecs describe-clusters --clusters $(aws ecs list-clusters --profile $PROFILE --region $REGION --output json | jq -r '.clusterArns | @tsv') \
  --profile $PROFILE --region $REGION --output json \
  | jq '.clusters[] | {clusterName, status, runningTasksCount, activeServicesCount}'
aws eks list-clusters --profile $PROFILE --region $REGION --output json | jq '.clusters'
```

TF: `aws_instance` `i-xxx`, `aws_ebs_volume` `vol-xxx`, `aws_lambda_function` <name>,
`aws_ecs_cluster` <name>, `aws_eks_cluster` <name>, `aws_launch_template` `lt-xxx`.

---

## Phase 4: Storage

**Skip if S3 buckets=0 and EFS=0.**

```bash
aws s3api list-buckets --profile $PROFILE --output json | jq '.Buckets | length'
aws s3api list-buckets --profile $PROFILE --output json | jq '.Buckets[] | {Name, CreationDate}'
# Per operational bucket (skip CDK/CodePipeline auto-named ones):
aws s3api get-bucket-location --bucket <B> --profile $PROFILE --output json
aws s3api get-bucket-versioning --bucket <B> --profile $PROFILE --output json
aws s3api get-bucket-encryption --bucket <B> --profile $PROFILE --output json
aws s3api get-public-access-block --bucket <B> --profile $PROFILE --output json
aws s3api get-bucket-lifecycle-configuration --bucket <B> --profile $PROFILE --output json
aws s3api get-bucket-tagging --bucket <B> --profile $PROFILE --output json 2>/dev/null || echo "No tags"
aws efs describe-file-systems --profile $PROFILE --region $REGION --output json \
  | jq '.FileSystems[] | {FileSystemId, LifeCycleState, SizeInBytes: .SizeInBytes.Value, Name: (.Tags[]? | select(.Key=="Name") | .Value), PerformanceMode, ThroughputMode}'
```

TF: `aws_s3_bucket` <name>, `aws_s3_bucket_versioning`, `aws_s3_bucket_lifecycle_configuration`,
`aws_s3_bucket_public_access_block`, `aws_efs_file_system` <fs-id>.

---

## Phase 5: Databases

**Skip if RDS=0, DynamoDB=0, ElastiCache=0, Redshift=0.**

```bash
aws rds describe-db-instances --profile $PROFILE --region $REGION --output json \
  | jq '.DBInstances[] | {DBInstanceIdentifier, Engine, EngineVersion, DBInstanceClass, MultiAZ, StorageEncrypted, DBInstanceStatus, AllocatedStorage}'
aws rds describe-db-clusters --profile $PROFILE --region $REGION --output json \
  | jq '.DBClusters[] | {DBClusterIdentifier, Engine, Status, MultiAZ, StorageEncrypted}'
aws rds describe-db-subnet-groups --profile $PROFILE --region $REGION --output json \
  | jq '.DBSubnetGroups[] | {DBSubnetGroupName, VpcId, SubnetIds: [.Subnets[] | .SubnetIdentifier]}'
aws dynamodb list-tables --profile $PROFILE --region $REGION --output json | jq '.TableNames'
# Per table:
aws dynamodb describe-table --table-name <T> --profile $PROFILE --region $REGION --output json \
  | jq '.Table | {TableName, BillingModeSummary, ItemCount, TableSizeBytes, KeySchema, SSEDescription}'
aws dynamodb describe-continuous-backups --table-name <T> --profile $PROFILE --region $REGION --output json \
  | jq '.ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus'
aws elasticache describe-cache-clusters --profile $PROFILE --region $REGION --output json \
  | jq '.CacheClusters[] | {CacheClusterId, Engine, CacheNodeType, CacheClusterStatus}'
aws redshift describe-clusters --profile $PROFILE --region $REGION --output json \
  | jq '.Clusters[] | {ClusterIdentifier, NodeType, ClusterStatus}'
```

TF: `aws_db_instance` <id>, `aws_rds_cluster` <id>, `aws_dynamodb_table` <name>,
`aws_elasticache_cluster` <id>, `aws_redshift_cluster` <id>.

---

## Phase 6: DNS & Discovery

**Skip if hosted zones=0 and Cloud Map namespaces=0.**

```bash
aws route53 list-hosted-zones --profile $PROFILE --output json \
  | jq '.HostedZones[] | {Id, Name, Private: .Config.PrivateZone, RecordSetCount}'
aws route53 list-resource-record-sets --hosted-zone-id <Z> --profile $PROFILE --output json \
  | jq '[.ResourceRecordSets[].Type] | group_by(.) | map({Type: .[0], Count: length}) | sort_by(-.Count)'
aws route53 list-health-checks --profile $PROFILE --output json | jq '.HealthChecks | length'
aws route53 get-dnssec --hosted-zone-id <Z> --profile $PROFILE --output json | jq '.Status'
aws servicediscovery list-namespaces --profile $PROFILE --region $REGION --output json \
  | jq '.Namespaces[] | {Id, Name, Type}'
aws route53resolver list-resolver-endpoints --profile $PROFILE --region $REGION --output json \
  | jq '.ResolverEndpoints | length'
aws route53domains list-domains --profile $PROFILE --region us-east-1 --output json \
  | jq '.Domains[] | {DomainName, AutoRenew, Expiry: .ExpirationDate}' 2>/dev/null || echo "AccessDenied or not available"
```

TF: `aws_route53_zone` <zone-id>, `aws_route53_record` `ZoneID_Name_Type`,
`aws_route53_health_check` <id>, `aws_service_discovery_*` <ns/svc-id>.

---

## Phase 7: Security & Governance

**Mandatory — never fully skip.**

```bash
aws iam list-roles --max-items 100 --profile $PROFILE --output json \
  | jq '{TotalRoles: (.Roles | length), SSO_Roles: [.Roles[] | select(.Path | startswith("/aws-reserved/sso.amazonaws.com/")) | .RoleName]}'
aws iam list-instance-profiles --profile $PROFILE --output json | jq '.InstanceProfiles | length'
aws cloudtrail describe-trails --profile $PROFILE --region $REGION --output json \
  | jq '.trailList[] | {Name, S3BucketName, IsMultiRegionTrail, IsOrganizationTrail, LogFileValidationEnabled, KmsKeyId}'
aws cloudtrail get-trail-status --name <TRAIL> --profile $PROFILE --region $REGION --output json \
  | jq '{IsLogging, LatestDeliveryTime, LatestDeliveryError}'
aws configservice describe-configuration-recorders --profile $PROFILE --region $REGION --output json \
  | jq '.ConfigurationRecorders[] | {Name, RoleARN, AllSupported: .recordingGroup.allSupported}'
aws configservice describe-config-rules --profile $PROFILE --region $REGION --output json \
  | jq '.ConfigRules | length'
aws guardduty list-detectors --profile $PROFILE --region $REGION --output json | jq '.DetectorIds'
# If detectors > 0:
aws guardduty get-detector --detector-id <ID> --profile $PROFILE --region $REGION --output json \
  | jq '{Status, FindingPublishingFrequency, DataSources}'
aws securityhub describe-hub --profile $PROFILE --region $REGION --output json 2>/dev/null \
  | jq '{HubArn, AutoEnableControls, ControlFindingGenerator}' || echo "Security Hub not enabled or AccessDenied"
aws securityhub get-enabled-standards --profile $PROFILE --region $REGION --output json 2>/dev/null \
  | jq '.StandardsSubscriptions | length' || echo "n/a"
aws kms list-keys --profile $PROFILE --region $REGION --output json | jq '.Keys | length'
# Per key (if ≤20): record KeyId, KeyState, KeyManager, Description — NEVER key material
aws inspector2 batch-get-account-status --profile $PROFILE --region $REGION --output json 2>/dev/null \
  | jq '.accounts[].state' || echo "Inspector not enabled or AccessDenied"
```

TF: `aws_iam_role` <name>, `aws_iam_policy` <arn>, `aws_cloudtrail` <name>,
`aws_config_configuration_recorder` <name>, `aws_guardduty_detector` <id>, `aws_kms_key` <id>.

---

## Phase 8: Monitoring

**Skip if log groups=0 and alarms=0.**

```bash
aws logs describe-log-groups --profile $PROFILE --region $REGION --output json \
  | jq '{TotalGroups: (.logGroups | length), TotalSizeBytes: ([.logGroups[] | .storedBytes] | add // 0), WithRetention: ([.logGroups[] | select(.retentionInDays)] | length), WithoutRetention: ([.logGroups[] | select(.retentionInDays | not)] | length)}'
aws logs describe-log-groups --profile $PROFILE --region $REGION --output json \
  | jq '[.logGroups[] | {LogGroup: .logGroupName, Size: .storedBytes, Retention: .retentionInDays}] | sort_by(-.Size) | .[0:10]'
aws cloudwatch describe-alarms --profile $PROFILE --region $REGION --output json \
  | jq '{OK: ([.MetricAlarms[] | select(.StateValue=="OK")] | length), ALARM: ([.MetricAlarms[] | select(.StateValue=="ALARM")] | length), INSUFFICIENT_DATA: ([.MetricAlarms[] | select(.StateValue=="INSUFFICIENT_DATA")] | length)}'
aws cloudwatch list-dashboards --profile $PROFILE --region $REGION --output json | jq '.DashboardEntries | length'
```

TF: `aws_cloudwatch_log_group` <name>, `aws_cloudwatch_metric_alarm` <name>,
`aws_cloudwatch_dashboard` <name>.

---

## Phase 9: Messaging & Integration

**Skip if SNS=0, SQS=0, EventBridge rules=0, Step Functions=0.**

```bash
aws sns list-topics --profile $PROFILE --region $REGION --output json | jq '.Topics | length'
aws sqs list-queues --profile $PROFILE --region $REGION --output json | jq '.QueueUrls | length'
aws events list-rules --profile $PROFILE --region $REGION --output json \
  | jq '.Rules[] | {Name, State, ScheduleExpression, Type: (if .EventPattern then "pattern" else "schedule" end)}'
# Per rule, check targets (a rule with 0 targets is inert — note it):
aws events list-targets-by-rule --rule <NAME> --profile $PROFILE --region $REGION --output json \
  | jq '.Targets | length'
aws stepfunctions list-state-machines --profile $PROFILE --region $REGION --output json \
  | jq '.stateMachines[] | {Name, Type, CreationDate}'
aws apigateway get-rest-apis --profile $PROFILE --region $REGION --output json | jq '.items | length'
aws apigatewayv2 get-apis --profile $PROFILE --region $REGION --output json | jq '.Items | length'
```

TF: `aws_sns_topic` <arn>, `aws_sqs_queue` <url>, `aws_cloudwatch_event_rule` <name>,
`aws_sfn_state_machine` <arn>, `aws_api_gateway_rest_api` <id>, `aws_apigatewayv2_api` <id>.

---

## Phase 10: Container Registry

**Skip if repositories=0.**

```bash
aws ecr describe-repositories --profile $PROFILE --region $REGION --output json \
  | jq '.repositories[] | {repositoryName, scanOnPush: .imageScanningConfiguration.scanOnPush, imageTagMutability, createdAt}'
```

TF: `aws_ecr_repository` <name>, `aws_ecr_lifecycle_policy` <name>.

---

## Phase 11: SSM

**Skip if parameters=0 and managed instances=0.**

```bash
# Names + types ONLY — never values (SecureString safety)
aws ssm describe-parameters --profile $PROFILE --region $REGION --output json \
  | jq '.Parameters[] | {Name, Type, Description, Version, LastModifiedDate}'
aws ssm describe-instance-information --profile $PROFILE --region $REGION --output json \
  | jq '.InstanceInformationList | length'
aws ssm list-documents --document-filter-list key=Owner,value=Self --profile $PROFILE --region $REGION --output json \
  | jq '.DocumentIdentifiers | length'
```

TF: `aws_ssm_parameter` <full-path-name>, `aws_ssm_document` <name>.

---

## Phase 12: Cost & Tagging

**Cost Explorer AccessDenied is expected for non-payer accounts — record as a finding.**

```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '-30 days' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --profile $PROFILE --region $REGION --output json 2>/dev/null \
  | jq '.ResultsByTime[0].Groups | sort_by(-.Metrics.BlendedCost.Amount | tonumber) | .[] | {Service: .Keys[0], Cost: .Metrics.BlendedCost.Amount}' \
  || echo "Cost Explorer not available (expected for non-payer accounts)"
aws budgets describe-budgets --account-id $ACCOUNT_ID --profile $PROFILE --output json 2>/dev/null \
  | jq '.Budgets | length' || echo "No budgets / AccessDenied"
aws resourcegroupstaggingapi get-tag-keys --profile $PROFILE --region $REGION --output json | jq '.TagKeys'
```

For a 3-month trend, run `--granularity MONTHLY` over a 3-month window — a rising
trend with no budget is a Cost Optimization finding for Phase 13.

---

## Error handling

| Error | Response |
|---|---|
| `AccessDenied` / `UnauthorizedOperation` | Record command + error + service as an IAM/SCP finding. Do NOT retry with another profile. Move on. |
| Empty result (0 resources) | Record count 0. If whole phase is 0, trigger skip. |
| Service unavailable in region | Try `us-east-1` for global services. Note which region worked. |
| `Throttling` / `RequestLimitExceeded` | Wait 5s, retry once. Still throttled → record and skip. |
| `OptInRequired` for region | Record as finding — region not enabled. Do not enable. |

---

## Output format

Write to `notes/<NN>-<account-name>.md` (continue the existing `NN` sequence in `notes/`).

```markdown
# Account Inspection: <ACCOUNT_NAME> (<ACCOUNT_ID>)

**Account:** … **ID:** … **Profile:** … **Role:** … **Region:** … **Date:** …

## Table of Contents
- [TL;DR](#tldr)
- Phases 1–13
- [Account Profile Summary](#account-profile-summary)
- [Key Findings](#key-findings)
- [Terraform Mapping](#terraform-mapping)
- [Commands Used](#commands-used)

## TL;DR
(3–5 sentences: account purpose, workloads, visible architecture patterns.)

## Phase N: <Title>
### Inventory  (table: Resource | Count | Details)
### Analysis   (what this profile says about the account's role)
(Skipped phases: `## Phase N: <Title> — SKIPPED (0 resources found)`.)

## Phase 13: Well-Architected Assessment
(6-pillar scorecard — see SKILL.md. No new API calls.)

## Account Profile Summary
(table: Primary workload type / Network model / Data stores / Security posture /
 Compute footprint / Cost indicators / Notable gaps)

## Key Findings
(table: # | Finding | Severity (info/low/medium/high) | Recommendation —
 every Phase 13 Weak/gap appears here)

## Terraform Mapping
(all phases' resources combined into one reference table)

## Commands Used
(every command run, for auditability)
```

---

## Post-inspection checklist

- [ ] All 12 phases executed or explicitly skipped with reason
- [ ] Phase 13 scorecard complete — all 6 pillars scored, no blank cells (use "Unknown")
- [ ] Every Weak pillar (and Adequate-with-gap) has a Key Findings row
- [ ] Key Findings has ≥3 entries (or "No significant findings" if truly clean)
- [ ] Account Profile Summary filled in
- [ ] No secrets, IPs, or internal hostnames in the output
- [ ] Commands Used lists every command
- [ ] Saved at `notes/<NN>-<account-name>.md`
