{
  _images+:: {
    alertmanager: "quay.io/cortexproject/alertmanager:%(image_tag)s" % $._config,
    configs: "quay.io/cortexproject/configs:%(image_tag)s" % $._config,
    consul: "consul:0.7.1",
    distributor: "quay.io/cortexproject/distributor:%(image_tag)s" % $._config,
    dynamodb: "deangiberson/aws-dynamodb-local",
    ingester: "quay.io/cortexproject/ingester:%(image_tag)s" % $._config,
    memcached: "memcached:1.4.25",
    nginx: "nginx",
    postgres: "postgres:9.6",
    prometheus: "prom/prometheus:v1.4.1",
    querier: "quay.io/cortexproject/querier:%(image_tag)s" % $._config,
    query_frontend: "quay.io/cortexproject/query-frontend:%(image_tag)s" % $._config,
    ruler: "quay.io/cortexproject/ruler:%(image_tag)s" % $._config,
    s3: "lphoward/fake-s3",
    table_manager: "quay.io/cortexproject/table-manager:%(image_tag)s" % $._config,
    watch: 'weaveworks/watch:master-5b2a6e5',
  }
}
