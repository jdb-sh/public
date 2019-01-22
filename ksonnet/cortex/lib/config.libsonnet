{
  _config+:: {
    namespace: "cortex",
    cluster_dns_suffix: "cluster.local",
    image_tag: "master-4e028c09",

    common_args: {
      "log.level": "debug",
    },

    consul_args: {
      "consul.hostname": "consul.%(namespace)s.svc.%(cluster_dns_suffix)s:8500" % $._config,
    },

    dynamodb_args: {
      "dynamodb.original-table-name": "cortex",
      "dynamodb.url": "dynamodb://user:pass@dynamodb.%(namespace)s.svc.%(cluster_dns_suffix)s:8000" % $._config,
      "dynamodb.periodic-table.prefix": "cortex_weekly_",
      "dynamodb.periodic-table.from": "2019-01-01",
      "dynamodb.daily-buckets-from": "2019-01-01",
      "dynamodb.base64-buckets-from": "2019-01-01",
      "dynamodb.chunk-table.from": "2019-01-01",
    },

    memcached_args: {
      "memcached.service": "memcached",
      "memcached.timeout": "100ms",
    },

    s3_args: {
      "s3.url": "s3://abc:123@%(namespace)s.svc.%(cluster_dns_suffix)s:4569/s3" % $._config,
    }
  }
}
