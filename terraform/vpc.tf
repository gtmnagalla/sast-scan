# Create VPC CIDR: 10.0.0.0/16
resource "aws_vpc" "app-vpc" {
    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = "true"

    tags = {
        Name = "3tier-vpc"
    }
}

# Create 6 subnets(2 public(web) and 4 private(2app and 2db))
resource "aws_subnet" "subnet-web-1a" {
    vpc_id     = aws_vpc.app-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "subnet-web-1a"
    }
}

resource "aws_subnet" "subnet-web-1b" {
    vpc_id     = aws_vpc.app-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"

    tags = {
        Name = "subnet-web-1b"
    }
}

resource "aws_subnet" "subnet-app-1a" {
    vpc_id     = aws_vpc.app-vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "subnet-app-1a"
    }
}

resource "aws_subnet" "subnet-app-1b" {
    vpc_id     = aws_vpc.app-vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "us-east-1b"

    tags = {
        Name = "subnet-app-1b"
    }
}

resource "aws_subnet" "subnet-db-1a" {
    vpc_id     = aws_vpc.app-vpc.id
    cidr_block = "10.0.5.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "subnet-db-1a"
    }
}
  
resource "aws_subnet" "subnet-db-1b" {
    vpc_id     = aws_vpc.app-vpc.id
    cidr_block = "10.0.6.0/24"
    availability_zone = "us-east-1b"
    
    tags = {
        Name = "subnet-db-1b"
    }
}

# Create Internet gateway and associate with VPC
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.app-vpc.id
}


# Create elastic ips
resource "aws_eip" "eip1" {
  domain   = "vpc"
}

resource "aws_eip" "eip2" {
  domain   = "vpc"
}

# Create nat gateways
resource "aws_nat_gateway" "ngw-1a" {
    allocation_id = aws_eip.eip1.id
    subnet_id     = aws_subnet.subnet-web-1a.id

    tags = {
        Name = "gw NAT az1"
    }

}

resource "aws_nat_gateway" "ngw-1b" {
    allocation_id = aws_eip.eip2.id
    subnet_id     = aws_subnet.subnet-web-1b.id

    tags = {
        Name = "gw NAT az2"
    }

}

## Create route tables for public subnet , app and db subnets ##
# Public subnet route table
resource "aws_route_table" "web-rtb" {
    vpc_id = aws_vpc.app-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "web route table"
    }
}

# App subnet route tables
resource "aws_route_table" "app-rtb1" {
    vpc_id = aws_vpc.app-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ngw-1a.id
    }

    tags = {
        Name = "app routetable1"
    }
}

resource "aws_route_table" "app-rtb2" {
    vpc_id = aws_vpc.app-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ngw-1b.id
    }

    tags = {
        Name = "app routetable2"
    }
}

# DB subnet
resource "aws_route_table" "db-rtb1" {
    vpc_id = aws_vpc.app-vpc.id

    tags = {
        Name = "db-rtb1"
    }
}

resource "aws_route_table" "db-rtb2" {
    vpc_id = aws_vpc.app-vpc.id

    tags = {
        Name = "db-rtb2"
    }
}

# Create route table associations
# web subnet and web route table association
resource "aws_route_table_association" "rta-web-1a" {
    subnet_id      = aws_subnet.subnet-web-1a.id
    route_table_id = aws_route_table.web-rtb.id
}
resource "aws_route_table_association" "rta-web-1b" {
    subnet_id      = aws_subnet.subnet-web-1b.id
    route_table_id = aws_route_table.web-rtb.id
}

# app subnet and app route table association
resource "aws_route_table_association" "rta-app-1a" {
    subnet_id      = aws_subnet.subnet-app-1a.id
    route_table_id = aws_route_table.app-rtb1.id
}
resource "aws_route_table_association" "rta-app-1b" {
    subnet_id      = aws_subnet.subnet-app-1b.id
    route_table_id = aws_route_table.app-rtb2.id
}

# db subnet and db route table association
resource "aws_route_table_association" "rta-db-1a" {
    subnet_id      = aws_subnet.subnet-db-1a.id
    route_table_id = aws_route_table.db-rtb1.id
}
resource "aws_route_table_association" "rta-db-1b" {
    subnet_id      = aws_subnet.subnet-db-1b.id
    route_table_id = aws_route_table.db-rtb2.id
}