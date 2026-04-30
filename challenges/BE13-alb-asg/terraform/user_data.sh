#!/bin/bash
dnf install -y httpd

# Dedicated health check endpoint — lightweight, no app logic
mkdir -p /var/www/html/health
echo "ok" > /var/www/html/health/index.html

# Fetch instance metadata using IMDSv2 (token-based, more secure than v1)
TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Write all files before starting httpd — avoids a window where Apache
# is live but serving nothing (would return 403, failing health checks)
cat > /var/www/html/index.html <<EOF
<html>
<body>
  <h2>Instance ID: ${INSTANCE_ID}</h2>
  <p>AZ: ${AZ}</p>
</body>
</html>
EOF

systemctl enable --now httpd
