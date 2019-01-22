{
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,

  query_frontend_container::
    container.new("query-frontend", $._images.query_frontend) +
    container.withArgs([
      "-server.http-listen-port=80",
      "-server.grpc-listen-port=9095"] +
      $.util.mapToFlags($._config.common_args)
    ) +
    container.withPortsMixin([
      containerPort.new("http-metrics", 80),
      containerPort.new("grpc", 9095),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  query_frontend_deployment:
    deployment.new("query-frontend", 1, [$.query_frontend_container]),

  query_frontend_service:
    $.util.serviceFor($.query_frontend_deployment),
}
