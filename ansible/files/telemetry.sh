TELEMETRY_CONF_BUCKET=s3://telemetry-presto-emr

# Install packages
sudo yum -y install git jq htop tmux aws-cli zsh

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

# Continue only if master node
if [ "$IS_MASTER" = false ]; then
    exit
fi
