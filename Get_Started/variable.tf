variable "AWS_ACCESS_KEY" {
    type = string
}

variable "AWS_SECRET_KEY" {
    type = string
}

variable "AWS_REGION" {
    type = string
    default = "us-east-2"
}

variable "AWS_AMI" {
    default =  {
        us-east-2 = "ami-07efac79022b86107"
        us-west-2 = "ami-06b94666"
        eu-west-1 = "ami-0d729a60"
    }
}