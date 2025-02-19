resource "aws_iam_instance_profile" "nat_profile" {
  name = "${var.name}-nat-profile"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name = "${var.name}-nat-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {"AWS": "*"},
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "modify_routes" {
  name = var.name
  role = "${aws_iam_role.role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Action": [
                "ec2:ReplaceRoute",
                "ec2:CreateRoute",
                "ec2:DeleteRoute",
                "ec2:DescribeRouteTables",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstanceAttribute"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}
