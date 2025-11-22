resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "main"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "main" {
  for_each = {
    for idx, cidr in var.subnet_cidr_blocks : cidr => {
      cidr_block        = cidr
      availability_zone = data.aws_availability_zones.available.names[idx % length(data.aws_availability_zones.available.names)]
    }
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags = {
    Name = "${var.prefix}-subnet-${replace(each.key, "/", "-")}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "main" {
  for_each       = toset(var.subnet_cidr_blocks)
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
  name        = "Allow SSH"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "sg_ssh" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "sg_http" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "main" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
