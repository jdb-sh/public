{
  _config+:: {
    namespace: "kube-system",
    # The location of the Calico etcd cluster.
    etcdEndpoints: error("Must provide the location of the Calico etcd cluster"),
    // Location of the CA certificate for etcd.
    etcdCACertFile: "",
    // Location of the client key for etcd.
    etcdKeyFile: "",
    // Location of the client certificate for etcd.
    etcdCertFile: "",
    // The default IPv4 pool to create on startup if none exists. Pod IPs will be
    // chosen from this range. Changing this value after installation will have
    // no effect. This should fall within `--cluster-cidr`.
    calicoIPv4PoolCIDR: "100.64.0.0/13",

    // CNI MTU Config variable
    vethMTU: "",

    kubeControllersReplicas: 1,
    # Choose which controllers to run.
    enabledControllers: "policy,namespace,serviceaccount,workloadendpoint,node",
  },
}
