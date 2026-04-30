resource "aws_launch_template" "web" {
  name        = "${var.project}-lt-${var.owner}"
  description = "Web server for BE13 — httpd via user data, returns instance ID"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Enforce IMDSv2 (token-required) and limit hop count to 1.
  # Hop limit 1 = only the EC2 itself can query metadata (not containers inside it).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # user_data.sh is a separate file — avoids heredoc escaping issues
  # and keeps ec2.tf readable.
  user_data = base64encode(file("${path.module}/user_data.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.project}-web-${var.owner}" }
  }

  tags = { Name = "${var.project}-lt-${var.owner}" }
}
