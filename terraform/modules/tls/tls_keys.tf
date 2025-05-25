resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "kafka-server-key"
  public_key = tls_private_key.this.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo "${tls_private_key.this.private_key_pem}" > kafka-server-key.pem
    EOT
  }
}

resource "tls_private_key" "this_two" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this_two" {
  key_name   = "logging-server-key"
  public_key = tls_private_key.this_two.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo "${tls_private_key.this_two.private_key_pem}" > logging-server-key.pem
    EOT
  }
}
