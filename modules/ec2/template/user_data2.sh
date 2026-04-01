#!/bin/bash

start=`date +%s`

# Install Packages
curl -L https://pkg.osquery.io/rpm/GPG | tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery
yum erase 'ntp*'
yum install yum-utils
yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
yum-config-manager --enable osquery-s3-rpm-repo
sudo amazon-linux-extras disable docker
sudo amazon-linux-extras install -y ecs epel
yum install -y jq chrony amazon-cloudwatch-agent osquery-5.8.2 clamav clamav-update

# s3 for logs
mkdir /opt/logs
sudo yum install s3fs-fuse -y 
s3fs ${logs_bucket} /opt/logs -o iam_role=auto -o nonempty
chmod +x /opt/logs/mvlogs.sh
crontab -l | { cat; echo "0 0 * * * /opt/logs/mvlogs.sh"; } | crontab -


#NTP Install
: > /etc/chrony.d/link-local.sources
echo "server 169.254.169.123 prefer iburst minpoll -4 maxpoll 0" >> /etc/chrony.d/link-local.sources
service chronyd restart
chkconfig chronyd on
chronyc sources -v
chronyc tracking

# ECS Config
echo ECS_CLUSTER=${task_cluster_name} >>/etc/ecs/ecs.config
echo ECS_RESERVED_MEMORY=1024 >>/etc/ecs/ecs.config
echo ECS_AWSVPC_BLOCK_IMDS=true >>/etc/ecs/ecs.config
echo ECS_IMAGE_PULL_BEHAVIOR=always >>/etc/ecs/ecs.config
echo ECS_WARM_POOLS_CHECK=true >>/etc/ecs/ecs.config
sudo systemctl enable --now --no-block ecs

# Memory Monitoring
echo '{
         "metrics":{
            "metrics_collected":{
               "mem":{
                  "measurement":[
                     "mem_used_percent"
                  ],
                  "metrics_collection_interval":30
               }
            }
         }
      }' | tee /opt/aws/amazon-cloudwatch-agent/bin/config.json

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s


cp /opt/osquery/share/osquery/osquery.example.conf /etc/osquery/osquery.conf
# Create the necessary files
sudo systemctl start osqueryd
sudo systemctl stop osqueryd
INSTANCE_ID="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
INSTANCE_TYPE=$(curl http://169.254.169.254/latest/meta-data/instance-type)
INSTANCE_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region)

echo "
--aws_region ap-south-1
--config_plugin=filesystem
--logger_plugin=aws_firehose,filesystem
--pidfile=/var/osquery/osquery.pidfile
--enable_file_events" | sudo tee /etc/osquery/osquery.flags
echo "{
  \"options\": {
    \"host_identifier\": \"$(echo $INSTANCE_ID)\",
    \"schedule_splay_percent\": 10,
    \"aws_firehose_stream\": \"fim-stream\",
    \"aws_region\": \"ap-south-1\",
    \"disable_events\": \"false\"
  },
  \"schedule\": {
    \"file_events\": {
      \"query\": \"SELECT * FROM file_events;\",
      \"removed\": false,
      \"interval\": 60
    }
  },
  \"file_paths\": {
         \"homes\": [
          \"/root/.ssh/%%\",
          \"/home/ec2-user/%%\",
          \"/sbin/%%\",
          \"/bin/%%\",
          \"/usr/sbin/%%\",
          \"/home/%/.ssh/%%\"
          ],
          \"etc\": [
            \"/etc/%%\"
           ]
  }
}" | sudo tee /etc/osquery/osquery.conf
sudo systemctl restart osqueryd

echo "LogFileMaxSize 2M" | tee -a  /etc/freshclam.conf
#echo "ConcurrentDatabaseReload no" | sudo tee -a  /etc/freshclam.conf
freshclam

mkdir -p /usr/local/clamav/log
mkdir -p /usr/local/clamav/script

echo '#!/bin/bash
LOG=/usr/local/clamav/log/clamav.log
TMP_LOG=/tmp/clam.daily
touch $(TMP_LOG)
clamscan -r / --exclude-dir=/sys/ --exclude-dir=/proc/ --quiet --infected --detect-structured --log=$(TMP_LOG)
cat $(TMP_LOG) >> $(LOG)
rm -rf $(TMP_LOG)
' | tee /usr/local/clamav/script/clamscan_daily

chmod +x /usr/local/clamav/script/clamscan_daily

echo '
/usr/local/clamav/log/*.log {
    daily
    dateext
    dateformat -%d%m%Y
    missingok
    rotate 90
    compress
    delaycompress
    notifempty
    create 600 root root
}' | tee -a /etc/logrotate.d/clamav

crontab -l | { cat; echo "01 00 * * * /usr/local/clamav/script/clamscan_daily"; } | crontab -

end=`date +%s`
runtime=$((end-start))

aws cloudwatch put-metric-data --namespace "ECS Meta Metrics" --metric-name "Time To initialize instance" --value $runtime \
--unit Seconds --dimensions InstanceType=$INSTANCE_TYPE --region=$INSTANCE_REGION