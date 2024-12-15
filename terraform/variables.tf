variable "app_name" {
    default="hextris-app"
    type = string
    description = "The name of the application"
}
variable "chart_location" {
    default="../hextris"
    type = string
    description = "The location of the helm chart"
}