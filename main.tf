data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami_name_pattern}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.ami_publisher}"]
}

data "aws_subnet" "first" {
  id = "${var.public_subnet_ids[0]}"
}

data "aws_vpc" "vpc" {
  id = "${data.aws_subnet.first.vpc_id}"
}

data "aws_region" "current" { }

data "template_file" "user_data" {
  template = "${file("${path.module}/nat-user-data.conf.tmpl")}"
  count    = "${var.instance_count}"

  vars = {
    name              = "${var.name}"
    mysubnet          = "${element(var.private_subnet_ids, count.index)}"
    vpc_cidr          = "${data.aws_vpc.vpc.cidr_block}"
    region            = "${data.aws_region.current.name}"
    awsnycast_deb_url = "${var.awsnycast_deb_url}"
    identifier        = "${var.route_table_identifier}"
  }
}

resource "aws_eip" "nat" {
  vpc       = true
  count     = "${var.instance_count}"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${element(aws_instance.nat.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
}

resource "aws_instance" "nat" {
  count                  = "${var.instance_count}"
  ami                    = "${data.aws_ami.ami.id}"
  instance_type          = "${var.instance_type}"
  source_dest_check      = false
  iam_instance_profile   = "${aws_iam_instance_profile.nat_profile.id}"
  key_name               = "${var.aws_key_name}"
  subnet_id              = "${element(var.public_subnet_ids, count.index)}"
  vpc_security_group_ids = "${var.vpc_security_group_ids}"
  tags                   = "${merge(var.tags, map("Name", format("%s-nat-%s", var.name, "test")))}"
  user_data              = "${element(data.template_file.user_data.*.rendered, count.index)}"
}
