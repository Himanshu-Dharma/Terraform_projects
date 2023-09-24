variable "public_subnet_cidrs" {
  type = string
  description = "publicc subnet CIDR values"
  default = "10.0.1.0/24"  #more values ["10.0.2.0/24", "10.0.3.0/24" ]
}

variable "private_subnet_cidrs" {
    type = list(string)
    description = "private subnet CIDR values"
    default = [ "10.0.5.0/24"]   #more values ["10.0.6.0/24", "10.0.7.0/24" ]
}

variable "interface_1_private_ip" {
  type = string
  description = "IP value of interface private ip"
  default =  "10.0.1.50/24"
}

variable "avail_zone" {
  type = string
  description = "availability zone"
  default = "eu-central-1a"
}