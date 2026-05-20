#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Create application directory
mkdir -p /opt/starttech
chown -R ec2-user:ec2-user /opt/starttech

# Create .env file for application
cat > /opt/starttech/.env << EOT
ENVIRONMENT=${environment}
PORT=8080
MONGO_URI=${mongodb_atlas_connection_string}
DB_NAME=much_todo_db
JWT_SECRET_KEY=change-me-in-production
JWT_EXPIRATION_HOURS=72
ENABLE_CACHE=true
REDIS_ADDR=localhost:6379
LOG_LEVEL=INFO
LOG_FORMAT=json
EOT

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOT'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/starttech/ec2/system",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/opt/starttech/logs/app.log",
            "log_group_name": "/starttech/application",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOT

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "EC2 instance bootstrap completed!"
