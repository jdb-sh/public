{
  local container = $.core.v1.container,

  configs_container::
    container.new("configs", $._images.configs) +
    container.withArgs([
      "-server.http-listen-port=80",
      "-database.uri=postgres://postgres@configs-db.%(namespace)s.svc/configs?sslmode=disable" % $._config,
      "-database.migrations=/migrations",
    ]) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http-metrics", 80),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  configs_deployment:
    deployment.new("configs", 1, [$.configs_container]),

  configs_service:
    $.util.serviceFor($.configs_deployment),
}
