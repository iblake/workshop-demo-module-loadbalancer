terraform {
  required_version = ">= 1.12"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.0, < 8.0"
    }
  }
}