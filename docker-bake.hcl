variable "TAG" {
    default = "1.24.0.labels"
}
group "default" {
    targets = ["proxy"]
}
target "proxy" {
    tags = ["pitilezard/nginx-proxy-swarm:${TAG}"]
    platforms = ["linux/arm64", "linux/amd64"]
}