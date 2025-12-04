variable "domain" { 
    type = string 
}
variable "hosted_zone_id" { 
    type = string 
}
variable "create_ecs" { 
    type = bool default = true 
}
variable "create_cloudfront" { 
    type = bool default = false 
}
variable "enable_ses" { 
    type = bool default = true 
}
variable "ecr_image" { 
    type = string default = "" 
} # e.g. ACCOUNT_ID.dkr.ecr...:sha
