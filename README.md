emr-bootstrap-presto
===================

This packages contains the AWS bootstrap scripts for Mozilla's flavoured Presto setup.

## Create Hive Metastore

```bash
export METASTORE_USERNAME=telemetry
export METASTORE_PASSWORD=somerandomstring

aws ec2 create-security-group \
  --group-name telemetry-metastore \
  --description telemetry-metastore

aws ec2 authorize-security-group-ingress \
  --group-name telemetry-metastore \
  --protocol tcp \
  --port 3306 \
  --source-group ElasticMapReduce-master

export METASTORE_SGID=$(aws ec2 describe-security-groups --group-names telemetry-metastore | jq -r '.SecurityGroups[0].GroupId')

aws rds create-db-instance \
  --db-name hive \
  --db-instance-identifier telemetry-metastore \
  --allocated-storage 8 \
  --db-instance-class db.t2.micro \
  --engine mariadb \
  --master-username $METASTORE_USERNAME \
  --master-user-password $METASTORE_PASSWORD \
  --vpc-security-group-ids $METASTORE_SGID
```

After creating this you'll want to modify ansible/files/configuration.json with the credentials you used as well as the correct endpoint of the RDS instance.

You can retrieve the RDS endpoint by running:

```bash
aws rds describe-db-instances --db-instance-identifier telemetry-metastore | jq '.DBInstances[0].Endpoint'
```

## Create EMR Cluster

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
  --release-label emr-4.7.2 \
  --applications Name=Presto-Sandbox \
  --bootstrap-actions Path=s3://${PRESTO_BUCKET}/bootstrap/telemetry.sh \
  --configurations https://s3-us-west-2.amazonaws.com/${PRESTO_BUCKET}/configuration/configuration.json \
  --tags REAPER_SPARE_ME="true"
```

## Deploy bootstrap scripts to AWS via ansible
```bash
ansible-playbook ansible/deploy_bootstrap.yml --extra-vars "@ansible/envs/dev.yml"
```
