{
  _config+:: {
    namespace: "kube-system",
    # The location of the Calico etcd cluster.
    etcdEndpoints: "cluster.local",
    // Location of the CA certificate for etcd.
    etcdCACertFile: "",
    // Location of the client key for etcd.
    etcdKeyFile: "",
    // Location of the client certificate for etcd.
    etcdCertFile: "",
    // The default IPv4 pool to create on startup if none exists. Pod IPs will be
    // chosen from this range. Changing this value after installation will have
    // no effect. This should fall within `--cluster-cidr`.
    calicoIPv4PoolCIDR: "",

    // CNI MTU Config variable
    vethMTU: "",
  },
}
