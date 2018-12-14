# Prometheus Custom Metrics API Server Ksonnet Library for Kubernetes
Ksonnet library for deploy the [k8s-prometheus-adapter](https://github.com/DirectXMan12/k8s-prometheus-adapter) to expose Prometheus metrics behind the Kubernetes custom metrics API.

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

Install the custom-metrics-apiserver library which will fetch its dependencies:

MacOS
```
$ go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
$ jb init
$ jb install github.com/jdb.sh/public/ksonnet/custom-metrics-apiserver

```

Assuming you want to run three replicas in the default namespace ('environment' in ksonnet parlance), add the follow to the file `environments/default/main.jsonnet`:

```
local custom-metrics-apiserver = import "custom-metrics-apiserver/custom-metrics-apiserver.libsonnet";

custom-metrics-apiserver {
  _config+:: {
    namespace: "default",
  },
}
```

Apply your config:

```
$ ks apply default
```

## Customising the deployment

The custom-metrics-apiserver ksonnet library allows you to easily configure a number of aspects of your custom-metrics-apiserver deployment using the ` _config+::` extension point. Of course, you can always use jsonnets late merging to add extra changes or modify objects that are no exposed by the config field.

| Key | Default | Description |
| --- | ------- | ----------- |
| name | "custom-metrics-apiserver" | The name of the adapter deployment and service accounts. |
| namespace | "kube-system" | Which namespace to deploy custom-metrics-apiserver. |

You can override the config source in your environment file:
```
local custom-metrics-apiserver = import "custom-metrics-apiserver/custom-metrics-apiserver.libsonnet";

custom-metrics-apiserver {
  _config+:: {
    name: "your-name"
    namespace: "kube-system",
  }
}
```
You can deploy your own configuration overriding the customMetricsAPIServerConfig object with your own config.yml:
```
local custom-metrics-apiserver = import "custom-metrics-apiserver/custom-metrics-apiserver.libsonnet";

custom-metrics-apiserver {
  customMetricsAPIServerConfig:: {
    "config.yml": |||
      rules:
      ...
    |||
  },
}
```
