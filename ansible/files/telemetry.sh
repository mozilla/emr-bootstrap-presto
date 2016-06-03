TELEMETRY_CONF_BUCKET=s3://telemetry-presto-emr

# Install packages
sudo yum -y install git jq htop tmux aws-cli zsh emacs
sudo pip install parquet2hive

# Check for master node
IS_MASTER=true
if [ -f /mnt/var/lib/info/instance.json ]
then
    IS_MASTER=$(jq .isMaster /mnt/var/lib/info/instance.json)
fi

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --public-key)
            shift
            PUBLIC_KEY=$1
            ;;
        --timeout)
            shift
            TIMEOUT=$1
            ;;
        -*)
            # do not exit out, just note failure
            echo 1>&2 "unrecognized option: $1"
            ;;
        *)
            break;
            ;;
    esac
    shift
done

# Add public key
if [ -n "$PUBLIC_KEY" ]; then
    echo $PUBLIC_KEY >> $HOME/.ssh/authorized_keys
fi

# Schedule shutdown at timeout
if [ ! -z $TIMEOUT ]; then
    sudo shutdown -h +$TIMEOUT&
fi

# Configure Presto and Hive after the services are up
# (EMR release doesn't allow to configure Presto's jvm.config)
PRESTO_CONFIG_SCRIPT=$(cat <<EOF
while ! pgrep presto > /dev/null; do sleep 1; done

# install presto plugins
sudo -u presto aws s3 sync $TELEMETRY_CONF_BUCKET/plugins/ /usr/lib/presto/plugin/

sudo sh -c "sudo cat <<EOF > /etc/presto/conf/jvm.config
-verbose:class
-server
-Xmx45G
-Xms45G
-Xmn512M
-XX:+UseConcMarkSweepGC
-XX:+ExplicitGCInvokesConcurrent
-XX:+CMSClassUnloadingEnabled
-XX:+AggressiveOpts
-XX:+HeapDumpOnOutOfMemoryError
-XX:OnOutOfMemoryError=kill -9 %p
-XX:ReservedCodeCacheSize=150M
-Xbootclasspath/p:
-Dhive.config.resources=/etc/hadoop/conf/core-site.xml,/etc/hadoop/conf/hdfs-site.xml
-Djava.library.path=/usr/lib/hadoop/lib/native/:/usr/lib/hadoop-lzo/lib/native/:/usr/lib/
EOF"
sudo pkill presto

# upgrade hive
tmp="\$(mktemp -d)"
cd "\$tmp"
v=1.2.1
aws s3 sync $TELEMETRY_CONF_BUCKET/packages/hive/\$v .
tar zxvf apache-hive-\$v-bin.tar.gz
mv apache-hive-\$v-bin /usr/lib/hive-\$v
cp -a /var/lib/hive /var/lib/hive-\$v
rm -rf /usr/lib/hive-\$v/conf
ln -t /usr/lib/hive-\$v -s /etc/hive/conf
cp hive-\$v-metastore.conf /etc/init/hive-\$v-metastore.conf
sed -i "s|/usr/lib/hive|/usr/lib/hive-\$v|" /usr/bin/hive
cp /usr/lib/hive/lib/mariadb-connector-java.jar /usr/lib/hive-\$v/lib/
# sed -i "s|org.mariadb.jdbc.Driver|com.mysql.jdbc.Driver|" /etc/hive/conf/hive-site.xml
initctl stop hive-metastore
initctl start hive-\$v-metastore
cd -
rm -rf "\$tmp"

# Load Parquet datasets into Hive
if [ "$IS_MASTER" = true ]; then
    /usr/local/bin/parquet2hive s3://telemetry-parquet/longitudinal | bash
    /usr/local/bin/parquet2hive s3://telemetry-parquet/executive_stream | bash
    /usr/local/bin/parquet2hive s3://net-mozaws-prod-us-west-2-pipeline-analysis/mfinkle/android_clients | bash
    /usr/local/bin/parquet2hive s3://net-mozaws-prod-us-west-2-pipeline-analysis/mfinkle/android_events | bash
fi

exit 0
EOF
)
echo "${PRESTO_CONFIG_SCRIPT}" | tee /tmp/presto_config.sh
chmod u+x /tmp/presto_config.sh
/tmp/presto_config.sh &
