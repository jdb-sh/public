{
  _config+:: {
    namespace: "kube-system",
    clusterDomain: "cluster.local",
    clusterIP: "100.64.0.10",
    replicas: 3,
    upstream: "/etc/resolv.conf",
  },
}
