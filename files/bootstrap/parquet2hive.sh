#!/bin/bash

set -exo pipefail

# exit if not master
jq -e '.isMaster' /mnt/var/lib/info/instance.json || exit 0

# create virtualenv
virtualenv $HOME/venv

# update pip
$HOME/venv/bin/pip install -U pip

# install parquet2hive
$HOME/venv/bin/pip install -U parquet2hive

# add cron entries
crontab <<EOF
0 12 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://telemetry-parquet/crash_aggregates | tee -a crash_aggregates.log | bash
3  0 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://telemetry-parquet/longitudinal | tee -a longitudinal.log | bash
3  1 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://telemetry-parquet/cross_sectional | tee -a cross_sectional.log | bash
9  9 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://telemetry-parquet/client_count | tee -a client_count.log | bash
0  8 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://telemetry-parquet/main_summary | tee -a main_summary.log | bash
0 11 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/mobile/android_clients | tee -a android_clients.log | bash
3 11 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/mobile/android_events | tee -a android_events.log | bash
6 11 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/mobile/android_addons | tee -a android_addons.log | bash
9 11 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/mobile/mobile_clients | tee -a mobile_clients.log | bash
0  9 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/ddurst/crash_stats_oom | tee -a crash_stats_oom.log | bash
0 10 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/isegall/usearch_daily | tee -a usearch_daily.log | bash
5 10 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/isegall/fxa_mau_dau_daily | tee -a fxa_mau_dau_daily.log | bash
15 10 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/isegall/txp_mau_dau_daily | tee -a txp_mau_dau_daily.log | bash
9 10 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/isegall/wayback_daily | tee -a wayback_daily.log | bash
9  5 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/isegall/vtabs_daily | tee -a vtabs_daily.log | bash
9 15 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/isegall/blok_daily | tee -a blok_daily.log | bash
9 20 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/isegall/minvid_daily | tee -a minvid_daily.log | bash
3  7 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://net-mozaws-prod-us-west-2-pipeline-analysis/mreid/socorro_crash | tee -a socorro_crash.log | bash
0  4 * * * $HOME/venv/bin/parquet2hive -ulv 1 s3://telemetry-parquet/sync_summary | tee -a sync_summary.log | bash
EOF
