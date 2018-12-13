# Weave Ksonnet Library for Kubernetes
A simple implementation of the Weave daemonset for Kubernetes using ksonnet. The CNI bin and net directories are default to the Kubelet defaults but are configurable using the `_config::` object.


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
$ jb install github.com/jdbaldry/jdb.sh/public/ksonnet/weave

```

Assuming you want to run three replicas in the kube-system namespace ('environment' in ksonnet parlance), add the follow to the file `environments/kube-system/main.jsonnet`:

```
local coredns = import "coredns/coredns.libsonnet";

coredns {
  _config+:: {
    namespace: "kube-system",
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
| cniBinDir | "/opt/cni/bin" | Directory in which the kubelet expects the CNI binaries. |
| cniNetDir | "/etc/cni/net.d" | Directory in which the kubelet expects the CNI net configuration. |
| namespace | "kube-system" | Which namespace to deploy weave. The kube-system namespace is recommended so that the weave pod can be treated as critical. |

You can override the config source in your environment file:
```
local weave = import "weave/weave.libsonnet";

weave {
  _config+:: {
    namespace: "kube-system",
    cniBinDir: "/your/cni/bin/dir",
    cniNetDir: "/your/cni/net/dir",
  }
}
