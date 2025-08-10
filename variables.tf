# =============================================================================
# LOAD BALANCER MODULE VARIABLES
# =============================================================================
# These variables define what the load balancer needs to work properly

# =============================================================================
# REQUIRED INPUTS FROM MAIN MODULE
# =============================================================================

variable "compartment_ocid" {
  description = "Oracle Cloud compartment ID - where to create the load balancer"
  type        = string
  # Example: "ocid1.compartment.oc1..aaaaaa..."
}

variable "subnet_ocids" {
  description = "List of PUBLIC subnet IDs where load balancer will be placed"
  type        = list(string)
  # Load balancer needs public subnets to receive internet traffic
  # Example: ["ocid1.subnet.oc1..publicb"]
}

variable "backend_ips" {
  description = "List of web server IP addresses to send traffic to"
  type        = list(string)
  # These are the private IP addresses of our web servers
  # Example: ["10.0.10.5", "10.0.10.6"] for 2 web servers
  # Comes from the compute module after servers are created
}

variable "common_tags" {
  description = "Standard tags applied to load balancer (for organization & billing)"
  type        = map(string)
  default     = {}
  # Example: { Environment = "dev", Project = "demo", ManagedBy = "terraform" }
}