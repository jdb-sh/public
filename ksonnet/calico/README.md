# Calico Ksonnet Library for Kubernetes
A configurable Calico ksonnet library for deployment to Kubernetes based on [Calico Version v3.3.1](https://docs.projectcalico.org/v3.3/releases#v3.3.1).

Currently only supports insecure connection to the Kubernetes etcd datastore.

> NOTE: This project is *alpha* stage. Flags, configuration, behaviour and design may change significantly in following releases.

## How to use

This library is designed to be vendored into the repo with your infrastructure config.
To do this, use [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler):

### Deployment
You will need to install the jsonnet-bundler and ksonnet tools. Make sure you have ksonnet v0.8.0.

MacOS
```
$ go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
$ brew install jsonnet
$ brew install https://raw.githubusercontent.com/ksonnet/homebrew-tap/82ef24cb7b454d1857db40e38671426c18cd8820/ks.rb
$ brew pin ks
$ ks version
ksonnet version: v0.8.0
jsonnet version: v0.9.5
client-go version: v1.6.8-beta.0+$Format:%h$
```
In your config repo, if you don't have a ksonnet application, make a new one (will copy credentials from current context):

```
$ ks init <application name>
$ cd <application name>
$ ks env add default
```

Install the calico library which will fetch its dependencies:

MacOS
```
$ go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
$ jb init
$ jb install github.com/jdbaldry/jdb.sh/public/ksonnet/calico

```

Assuming you want to run three replicas in the kube-system namespace ('environment' in ksonnet parlance), add the follow to the file `environments/kube-system/main.jsonnet`:

```
local calico = import "calico/calico.libsonnet";

calico {
  _config+:: {
    namespace: "kube-system",
    replicas: 3,
  },
}
```

Apply your config:

```
$ ks apply kube-system
```

## Customising the deployment

The calico ksonnet library allows you to easily configure a number of aspects of your calico deployment using the ` _config+::` extension point. Of course, you can always use jsonnets lazy merging to add extra changes or modify objects that are not exposed by the config field.

| Key | Default | Description |
| --- | ------- | ----------- |
| namespace | "kube-system" | Which namespace to deploy calico to. |
| calicoIPv4PoolCIDR | "100.64.0.0/13" | The default IPv4 pool to create on startup if none exists. Pod IPs will be chosen from this range. Changing this value after installation will have no effect. This should fall within `--cluster-cidr`. |
| enabledControllers | "policy,namespace,serviceaccount,workloadendpoint,node" | The calico-kube-controllers controllers to run. |
| etcdEndpoints | Required | The location of the Calico etcd cluster. |
| etcdCACertFile | "" | Location of the CA certificate for etcd. |
| etcdKeyFile | "" | Location of the client key for etcd. |
| etcdCertFile | "" | Location of the client certificate for etcd. |
| kubeControllersReplicas  | 1 | Number of calico-kube-controllers replicas. |
| vethMTU | "" | CNI MTU Config variable. |


You can override the config source in your environment file:
```
local calico = import "calico/calico.libsonnet";

calico {
  _config+:: {
    etcdEndpoints: "<etcd endpoints>",
  }
}
```
