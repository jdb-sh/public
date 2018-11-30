# CoreDNS Ksonnet Library for Kubernetes
A configurable CoreDNS deployment for Kubernetes using ksonnet. As coredns uses a configmap for most of its configuration, modifying to suit your needs is as simple as redefining the Corefile data.

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

Install the coredns library which will fetch its dependencies:

MacOS
```
$ go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
$ jb init
$ jb install github.com/jdbaldry/jdb.sh/public/ksonnet/coredns

```

Assuming you want to run three replicas in the kube-system namespace ('environment' in ksonnet parlance), add the follow to the file `environments/kube-system/main.jsonnet`:

```
local coredns = import "coredns/coredns.libsonnet";

coredns {
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

The coreDNS ksonnet library allows you to easily configure a number of aspects of your coreDNS deployment using the ` _config+::` extension point. Of course, you can always use jsonnets lazy merging to add extra changes or modify objects that are no exposed by the config field.

| Key | Default | Description |
| --- | ------- | ----------- |
| replicas  | 3 | Number of coredns replicas. |
| clusterDomain | "cluster.local" | The cluster domain used for in cluster name resolution. |
| clusterIP | "100.64.0.10" | ClusterIP of for kube-dns service. |
| upstream | "/etc/resolv.conf" | Source of upstream DNS. |

You can override the config source in your environment file:
```
local coredns = import "coredns/coredns.libsonnet";

coredns {
  _config+:: {
    clusterDomain: "cluster.local",
    replicas: 3,
  }

  corednsConfig:: (import "/path/to/your/Corefile.libsonnet")
}
