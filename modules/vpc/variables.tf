variable "project" {
  description = "Name of the project"
  type        = string
}

variable "env" {
  description = "Environment (e.g., prod, dev)"
  type        = string
}

variable "base_cidr_block" {
  description = "The base CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "azs" {
  description = "List of availability zones (optional, will be auto-detected if not provided)"
  type        = list(string)
  default     = null
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 