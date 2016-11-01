# emr-bootstrap-presto

This repo contains the CloudFormation templates and bootstrap scripts for
setting up Mozilla's Presto cluster.

## Prerequisites
* ansible >= 2.2.0.0
* boto
* boto3

## Creating Stacks

### Metastore
```bash
ansible-playbook \
  playbooks/metastore.yml \
  -e @envs/dev.yml \
  -e owner=<yourname>@mozilla.com
```

### Presto
```bash
ansible-playbook \
  playbooks/presto.yml \
  -e @envs/dev.yml \
  -e owner=<yourname>@mozilla.com
```

## Deploying Bootstrap Scripts

```bash
ansible-playbook \
  playbooks/bootstrap.yml \
  -e @envs/dev.yml
```

## Modifying Variables

Besides the `owner` variable specified when creating the stack, everything lives
in `vars/default.yml` and `envs/<env>.yml`. Any of these can be overridden at
runtime by using the `-e` flag just as you did with `owner`.
