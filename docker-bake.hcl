variable "TAG" {
    default = "1.27.3.labels"
}
group "default" {
    targets = ["proxy"]
}
target "proxy" {
    tags = ["pitilezard/nginx-proxy-swarm:${TAG}"]
    platforms = ["linux/amd64"]
}