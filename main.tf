provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "codebolab_cluster" {
  cidr_block = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Environment = "development"
    Name        = "cluster-enapp-development"
  }
}

resource "aws_subnet" "public_a" {
  cidr_block = "10.0.0.128/26"
  vpc_id     = aws_vpc.codebolab_cluster.id

  tags = {
    Environment = "development"
    Name        = "public-a"
  }
}

resource "aws_subnet" "public_b" {
  cidr_block = "10.0.0.192/26"
  vpc_id     = aws_vpc.codebolab_cluster.id

  tags = {
    Environment = "development"
    Name        = "public-b"
  }
}

resource "aws_security_group" "allow_private_http" {
  description = "Allow private web traffic"
  name        = "allow-private-http"
  vpc_id      = aws_vpc.codebolab_cluster.id

  ingress {
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
}

resource "aws_security_group" "allow_private_ssh" {
  description = "Allow SSH from anyone on Clear VPN"
  name        = "allow-private-ssh"
  vpc_id      = aws_vpc.codebolab_cluster.id

  ingress {
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
}

resource "aws_security_group" "default" {
  description = "default VPC security group"
  name        = "default"
  vpc_id      = aws_vpc.codebolab_cluster.id

  ingress {
    from_port = 0
    protocol  = "-1"
    self      = true
    to_port   = 0
  }
}

resource "aws_security_group" "limited_ec" {
  description = "Limited and private accesss only to instances from instances"
  name        = "limited-ec"
  vpc_id      = aws_vpc.codebolab_cluster.id

  ingress {
    from_port = 6379
    protocol  = "tcp"
    self      = true
    to_port   = 6379
  }
}

resource "aws_security_group" "limited_public_https" {
  description = "Limit http traffic"
  name        = "limited-public-https"
  vpc_id      = aws_vpc.codebolab_cluster.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8000
    protocol    = "tcp"
    to_port     = 8000
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
  }
}

resource "aws_security_group" "limited_public_ssh" {
  description = "Only allow ssh connections from Clear internet gateway IP"
  name        = "limited-public-ssh"
  vpc_id      = aws_vpc.codebolab_cluster.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
}

resource "aws_security_group" "limited_rds" {
  description = "Limited and private accesss only to instances from microservices"
  name        = "limited-rds"
  vpc_id      = aws_vpc.codebolab_cluster.id

  ingress {
    from_port = 0
    protocol  = "tcp"
    self      = true
    to_port   = 65535
  }

  ingress {
    from_port       = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.limited_public_https.id]
    to_port         = 5432
  }
}

resource "aws_route53_zone" "webeando_me" {
  name = "webeando.me"
}

resource "aws_route53_zone" "josezambrana_com" {
  name = "josezambrana.com"
}

resource "aws_route53_zone" "code_bo" {
  name = "code.bo"
}

resource "aws_route53_record" "code_bo_A" {
  name    = "code.bo"
  records = ["18.207.38.109"]
  ttl     = 300
  type    = "A"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "code_bo_MX" {
  name    = "code.bo"
  records = ["1 ASPMX.L.GOOGLE.COM", "10 ALT3.ASPMX.L.GOOGLE.COM", "10 ALT4.ASPMX.L.GOOGLE.COM", "5 ALT1.ASPMX.L.GOOGLE.COM", "5 ALT2.ASPMX.L.GOOGLE.COM"]
  ttl     = 3600
  type    = "MX"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "code_bo_NS" {
  name    = "code.bo"
  records = ["ns-1449.awsdns-53.org.", "ns-2008.awsdns-59.co.uk.", "ns-41.awsdns-05.com.", "ns-595.awsdns-10.net."]
  ttl     = 172800
  type    = "NS"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "code_bo_SOA" {
  name    = "code.bo"
  records = ["ns-1449.awsdns-53.org. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
  ttl     = 900
  type    = "SOA"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "code_bo_TXT1" {
  name    = "code.bo"
  records = ["google-site-verification=ExqTC1Bn10qrmbMs5LP8M5yITsDun-ce3eH7PP5fUKQ"]
  ttl     = 300
  type    = "TXT"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "code_bo_TXT2" {
  name    = "_amazonses.code.bo"
  records = ["U7qjn9fxH8wf98Z0Rser8XDMq+ZbTfaeZ83eJrQbY0c="]
  ttl     = 300
  type    = "TXT"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "bbbf_code_bo_CNAME" {
  name    = "_4cb2c0de6fd054f63eea9c24ad7abbbf.code.bo"
  records = ["_8f82125cbf1ce60e573cf1abb68be73f.auiqqraehs.acm-validations.aws."]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "domainkey1_code_bo_CNAME" {
  name    = "6bqo4vi5awctoiwq5pfsg2n6gk5qdc3k._domainkey.code.bo"
  records = ["6bqo4vi5awctoiwq5pfsg2n6gk5qdc3k.dkim.amazonses.com"]
  ttl     = 1800
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "domainkey2_code_bo_CNAME" {
  name    = "kq435ljkvt4u2ovlbpzzrzoifh7hrkjv._domainkey.code.bo"
  records = ["kq435ljkvt4u2ovlbpzzrzoifh7hrkjv.dkim.amazonses.com"]
  ttl     = 1800
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "domainkey3_code_bo_CNAME" {
  name    = "pc3w7xx4cn5gcrdpbm2jue6rfpukq3pi._domainkey.code.bo"
  records = ["pc3w7xx4cn5gcrdpbm2jue6rfpukq3pi.dkim.amazonses.com"]
  ttl     = 1800
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "academy_staging_code_bo_CNAME" {
  name    = "academy-staging.code.bo"
  records = ["d15wz72zj8a0zs.cloudfront.net"]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "academy_code_bo_CNAME" {
  name    = "academy.code.bo"
  records = ["d1vbg2jzrh9vx2.cloudfront.net"]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "api_staging_code_bo_A" {
  alias {
    evaluate_target_health = true
    name                   = "dualstack.api-staging-alb-1503785796.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K"
  }
  name    = "api-staging.code.bo"
  type    = "A"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "api_code_bo_A" {
  alias {
    evaluate_target_health = true
    name                   = "api-alb-496127464.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K"
  }
  name    = "api.code.bo"
  type    = "A"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "cdn_staging_code_bo_CNAME" {
  name    = "cdn-staging.code.bo"
  records = ["d2kpztkwc9pohq.cloudfront.net"]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "cdn_code_bo_CNAME" {
  name    = "cdn.code.bo"
  records = ["d3ggdmudu580np.cloudfront.net"]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "secrets_code_bo_CNAME" {
  name    = "secrets.code.bo"
  records = ["d3o3px7698ddxz.cloudfront.net"]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "www_code_bo_CNAME" {
  name    = "www.code.bo"
  records = ["code.bo"]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_route53_record" "academyv2_code_bo_CNAME" {
  name    = "academyv2.code.bo"
  records = ["code.bo"]
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.code_bo.zone_id
}

resource "aws_instance" "cluster_head" {
  ami           = "ami-0323c3dd2da7fb37d"
  instance_type = "t3.small"
  key_name      = "cluster-enapp-development"
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Environment = "development"
    Name        = "cluster-enapp-development-head"
    VPC         = "cluster-enapp-development"
  }
}

resource "aws_eip" "head_ip" {
  instance = aws_instance.cluster_head.id

  tags = {
    Name = "cluster-enapp-development-head"
  }
}
