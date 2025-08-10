# =============================================================================
# LOAD BALANCER MODULE - DISTRIBUTES TRAFFIC TO WEB SERVERS
# =============================================================================
# SETUP:
# - Public load balancer (has internet-facing IP address)
# - Routes HTTP traffic to private web servers
# - Automatic failover if a web server becomes unhealthy
# =============================================================================

# =============================================================================
# LOAD BALANCER - THE TRAFFIC DISTRIBUTOR
# =============================================================================
resource "oci_load_balancer" "lb" {
  compartment_id = var.compartment_ocid # Where to create the load balancer
  display_name   = "demo-lb"            # Name shown in Oracle Cloud console

  # NETWORK PLACEMENT: Put load balancer in public subnets (internet access required)
  subnet_ids = var.subnet_ocids # List of public subnet IDs from network module

  # PERFORMANCE CONFIGURATION: Flexible shape allows auto-scaling bandwidth
  shape = "flexible" # Auto-adjusts capacity based on traffic
  shape_details {
    minimum_bandwidth_in_mbps = 10 # Minimum: 10 Mbps (good for demo)
    maximum_bandwidth_in_mbps = 20 # Maximum: 20 Mbps (cost control)
  }

  # Tags for organization
  freeform_tags = merge(var.common_tags, {
    Tier = "loadbalancer" # This is the load balancing tier
  })
}

# =============================================================================
# BACKEND SET - DEFINES HOW TO DISTRIBUTE TRAFFIC TO WEB SERVERS
# =============================================================================
# CONFIGURATION:
# - ROUND_ROBIN: Send requests to each server in turn (server1, server2, server1, server2...)
# - Health checks: Every few seconds, check if servers are responding
# - If a server fails health checks, stop sending traffic to it

resource "oci_load_balancer_backend_set" "bs" {
  name             = "demo_bs"               # Name for this backend set
  load_balancer_id = oci_load_balancer.lb.id # Attach to our load balancer
  policy           = "ROUND_ROBIN"           # Traffic distribution: rotate between servers

  # HEALTH CHECK CONFIGURATION: How to verify servers are working
  health_checker {
    protocol          = "HTTP"    # Use HTTP requests to check health
    port              = 80        # Check on port 80 (standard web port)
    url_path          = "/health" # Check the "/health" endpoint on each server
    timeout_in_millis = 3000      # Wait 3 seconds for response before considering it failed
    retries           = 3         # Try 3 times before marking server as unhealthy
    # If server doesn't respond to "/health" requests, remove it from rotation
  }
}

# =============================================================================
# BACKEND SERVERS - REGISTER EACH WEB SERVER WITH THE LOAD BALANCER
# =============================================================================
# DYNAMIC REGISTRATION:
# - We don't know server IPs until Terraform creates them
# - Use count.index to create one backend resource per web server
# - IP addresses come from the compute module after servers are created

resource "oci_load_balancer_backend" "backend" {
  count = length(var.backend_ips) # Create one backend per web server IP

  load_balancer_id = oci_load_balancer.lb.id               # Which load balancer to use
  backendset_name  = oci_load_balancer_backend_set.bs.name # Which backend set to join
  ip_address       = var.backend_ips[count.index]          # IP address of this web server (from compute module)
  port             = 80                                    # Port where web server listens (HTTP)
  weight           = 1                                     # Traffic weight: 1 = equal distribution

  # Example: If we have 2 web servers with IPs 10.0.10.5 and 10.0.10.6
  # This creates 2 backend resources pointing to those IPs
}

# =============================================================================
# LISTENER - THE FRONT DOOR OF THE LOAD BALANCER
# =============================================================================
# SETUP:
# - Listen on port 80 (HTTP)
# - Forward all requests to our web server backend set
# - Users will connect to: http://<load_balancer_ip>/

resource "oci_load_balancer_listener" "listener" {
  load_balancer_id         = oci_load_balancer.lb.id               # Which load balancer to attach to
  name                     = "demo_listener"                       # Name for this listener
  default_backend_set_name = oci_load_balancer_backend_set.bs.name # Send traffic to our web servers
  port                     = 80                                    # Listen on HTTP port 80
  protocol                 = "HTTP"                                # Handle HTTP requests

  # When users visit http://<load_balancer_ip>/, this listener receives the request
  # and forwards it to one of our web servers in the backend set
}

# =============================================================================
# OUTPUTS - INFORMATION WE NEED AFTER DEPLOYMENT
# =============================================================================

output "lb_public_ip" {
  description = "Public IP address of the load balancer (your website URL)"
  value       = oci_load_balancer.lb.ip_address_details[0].ip_address
  # This is the IP address users will use to access your website
  # Example: http://203.0.113.10/
}

output "lb_id" {
  description = "Oracle Cloud ID of the load balancer (for management)"
  value       = oci_load_balancer.lb.id
  # Internal ID used by Oracle Cloud to identify this load balancer
}
