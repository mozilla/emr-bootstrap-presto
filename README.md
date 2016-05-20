emr-bootstrap-presto
===================

This packages contains the AWS bootstrap scripts for Mozilla's flavoured Presto setup.

## Interactive job
```bash
export PRESTO_BUCKET=telemetry-presto-emr
export KEY_NAME=20151209-cloudservices-aws-ssh-dev
aws emr create-cluster \
  --region us-west-2 \
  --name PrestoCluster \
  --instance-type r3.2xlarge \
  --instance-count 11 \
  --service-role EMR_DefaultRole \
  --ec2-attributes KeyName=${KEY_NAME},InstanceProfile=EMR_EC2_DefaultRole,AdditionalMasterSecurityGroups=sg-263db541 \
  --release-label emr-4.3.0 \
  --applications Name=Presto-Sandbox \
  --bootstrap-actions Path=s3://${PRESTO_BUCKET}/bootstrap/telemetry.sh \
  --configurations https://s3-us-west-2.amazonaws.com/${PRESTO_BUCKET}/configuration/configuration.json
```

## Deploy bootstrap scripts to AWS via ansible
```bash
ansible-playbook ansible/deploy_bootstrap.yml --extra-vars "@ansible/envs/dev.yml" -i ansible/inventory
```
