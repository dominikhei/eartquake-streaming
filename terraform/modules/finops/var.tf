variable "site_version" {
  description = "The version of the finops dashboard (v:n)."
  type        = string
}

variable "my_ip" {
  description = "Your local IP address. Access to the dashboard will be limited to it."
  type        = string
}
