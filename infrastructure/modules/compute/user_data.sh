#!/bin/bash

# Update the system
sudo yum update -y

# Install required packages
sudo yum install -y awscli htop tree

# Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent

# Configure AWS CLI region
echo "[default]" > /home/ec2-user/.aws/config
echo "region = us-east-1" >> /home/ec2-user/.aws/config
echo "output = json" >> /home/ec2-user/.aws/config
chown ec2-user:ec2-user /home/ec2-user/.aws/config

# Create S3 test script for VPC endpoint validation
cat > /home/ec2-user/test-s3-access.sh << 'EOF'
#!/bin/bash
echo "=== Testing S3 VPC Endpoint Access ==="
echo "Date: $(date)"
echo ""

# Test basic S3 connectivity
echo "1. Testing S3 connectivity via VPC endpoint..."
aws s3 ls --region us-east-1 2>&1
if [ $? -eq 0 ]; then
    echo "✓ S3 connectivity working"
else
    echo "✗ S3 connectivity failed"
fi

echo ""
echo "2. VPC Endpoint routing check..."
# Check if S3 traffic goes through VPC endpoint (no internet)
traceroute -n s3.amazonaws.com 2>/dev/null | head -5

echo ""
echo "3. Checking S3 bucket access (will be available after deployment)..."
# This will be populated with actual bucket name during deployment
if [ ! -z "$S3_BUCKET_NAME" ]; then
    aws s3 ls s3://$S3_BUCKET_NAME/ 2>&1
else
    echo "Bucket name not yet configured"
fi

echo ""
echo "=== Test completed ==="
EOF

chmod +x /home/ec2-user/test-s3-access.sh
chown ec2-user:ec2-user /home/ec2-user/test-s3-access.sh

# Create sample upload script for S3
cat > /home/ec2-user/upload-to-s3.sh << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <file-to-upload>"
    echo "Example: $0 test-file.txt"
    exit 1
fi

if [ -z "$S3_BUCKET_NAME" ]; then
    echo "Error: S3_BUCKET_NAME environment variable not set"
    echo "Please set it with: export S3_BUCKET_NAME=your-bucket-name"
    exit 1
fi

FILE_TO_UPLOAD="$1"
if [ ! -f "$FILE_TO_UPLOAD" ]; then
    echo "Error: File $FILE_TO_UPLOAD not found"
    exit 1
fi

echo "Uploading $FILE_TO_UPLOAD to S3 bucket $S3_BUCKET_NAME..."
aws s3 cp "$FILE_TO_UPLOAD" "s3://$S3_BUCKET_NAME/" --region us-east-1

if [ $? -eq 0 ]; then
    echo "✓ File uploaded successfully"
    echo "File URL: https://$S3_BUCKET_NAME.s3.amazonaws.com/$(basename $FILE_TO_UPLOAD)"
else
    echo "✗ Upload failed"
fi
EOF

chmod +x /home/ec2-user/upload-to-s3.sh
chown ec2-user:ec2-user /home/ec2-user/upload-to-s3.sh

# Create a simple web server
sudo yum install -y httpd php
sudo systemctl enable httpd
sudo systemctl start httpd

# Create API endpoints for backend communication
sudo mkdir -p /var/www/html/api

# Create simple Hello World API endpoint
cat > /var/www/html/api/hello.php << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Get instance metadata
$instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
$availability_zone = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');
$private_ip = file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4');

$response = array(
    'message' => 'Hello World from Villa Alfredo EC2!',
    'status' => 'success',
    'instance_info' => array(
        'instance_id' => trim($instance_id),
        'availability_zone' => trim($availability_zone),
        'private_ip' => trim($private_ip)
    ),
    'timestamp' => date('c'),
    'uptime' => shell_exec('uptime -s')
);

echo json_encode($response, JSON_PRETTY_PRINT);
?>
EOF

# Create health check endpoint
cat > /var/www/html/health.php << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$response = array(
    'status' => 'healthy',
    'timestamp' => date('c'),
    'uptime' => trim(shell_exec('uptime -s')),
    'load_average' => sys_getloadavg(),
    'disk_usage' => shell_exec("df -h / | awk 'NR==2{print $5}'")
);

echo json_encode($response, JSON_PRETTY_PRINT);
?>
EOF

# Configure Apache to handle .php files and API routes
cat > /etc/httpd/conf.d/api.conf << 'EOF'
<Directory "/var/www/html/api">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# Rewrite rules for cleaner API URLs
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^api/hello$ /api/hello.php [L]
    RewriteRule ^health$ /health.php [L]
</IfModule>
EOF

# Enable mod_rewrite
sudo systemctl restart httpd

# Create a simple HTML page with instance information
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Villa Alfredo - EC2 Instance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .info-box { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
        h1 { color: #333; }
        .status { color: #27ae60; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏠 Villa Alfredo - Infrastructure</h1>
        <div class="info-box">
            <h3>Instance Information</h3>
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Availability Zone:</strong> $AVAILABILITY_ZONE</p>
            <p><strong>Private IP:</strong> $PRIVATE_IP</p>
            <p><strong>Status:</strong> <span class="status">Running ✓</span></p>
        </div>
        <div class="info-box">
            <h3>VPC Endpoints Configuration</h3>
            <p>✓ S3 VPC Endpoint configured for private access</p>
            <p>✓ CloudWatch VPC Endpoint configured for monitoring</p>
            <p>✓ NAT Gateway configured for internet access</p>
        </div>
        <div class="info-box">
            <h3>S3 Integration</h3>
            <p>✓ AWS CLI configured for S3 access via VPC endpoint</p>
            <p>✓ S3 access scripts available in /home/ec2-user/</p>
            <p>• test-s3-access.sh - Test VPC endpoint connectivity</p>
            <p>• upload-to-s3.sh - Upload files to S3 bucket</p>
        </div>
        <div class="info-box">
            <h3>Architecture Flow</h3>
            <p><strong>To S3:</strong> EC2 → VPC Endpoint → S3</p>
            <p><strong>To Users:</strong> S3 → CloudFront → Global Users</p>
            <p><strong>APIs:</strong> EC2 → ALB → API Gateway → CloudFront → Users</p>
        </div>
    </div>
</body>
</html>
EOF

# Test VPC endpoints connectivity
echo "=== VPC Endpoints Connectivity Test ===" >> /var/log/vpc-endpoint-test.log
echo "Date: $(date)" >> /var/log/vpc-endpoint-test.log

echo "Testing S3 VPC endpoint..." >> /var/log/vpc-endpoint-test.log
aws s3 ls --region us-east-1 >> /var/log/vpc-endpoint-test.log 2>&1
S3_RESULT=$?

echo "Testing CloudWatch Logs VPC endpoint..." >> /var/log/vpc-endpoint-test.log
aws logs describe-log-groups --region us-east-1 --max-items 1 >> /var/log/vpc-endpoint-test.log 2>&1
CW_RESULT=$?

echo "Testing CloudWatch Monitoring VPC endpoint..." >> /var/log/vpc-endpoint-test.log
aws cloudwatch list-metrics --region us-east-1 --max-records 1 >> /var/log/vpc-endpoint-test.log 2>&1
CWM_RESULT=$?

echo "=== Test Results ===" >> /var/log/vpc-endpoint-test.log
echo "S3 VPC Endpoint: $([ $S3_RESULT -eq 0 ] && echo 'SUCCESS' || echo 'FAILED')" >> /var/log/vpc-endpoint-test.log
echo "CloudWatch Logs VPC Endpoint: $([ $CW_RESULT -eq 0 ] && echo 'SUCCESS' || echo 'FAILED')" >> /var/log/vpc-endpoint-test.log
echo "CloudWatch Monitoring VPC Endpoint: $([ $CWM_RESULT -eq 0 ] && echo 'SUCCESS' || echo 'FAILED')" >> /var/log/vpc-endpoint-test.log

# Run the S3 test script
echo "Running S3 access test..." >> /var/log/vpc-endpoint-test.log
/home/ec2-user/test-s3-access.sh >> /var/log/vpc-endpoint-test.log 2>&1

# Configure CloudWatch Agent for basic monitoring
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "diskio": {
                "measurement": ["io_time"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "villa-alfredo-apache-access",
                        "log_stream_name": "{instance_id}-apache-access"
                    },
                    {
                        "file_path": "/var/log/vpc-endpoint-test.log",
                        "log_group_name": "villa-alfredo-vpc-endpoints",
                        "log_stream_name": "{instance_id}-vpc-test"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "User data script completed successfully" >> /var/log/user-data.log