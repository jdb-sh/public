{
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,

  consul_container::
    container.new("consul", $._images.consul) +
    container.withArgs([
      "agent",
      "-ui",
      "-server",
      "-client=0.0.0.0",
      "-bootstrap",
    ]) +
    container.withEnv({
      name: "CHECKPOINT_DISABLE",
      value: "1",
    }) +
    container.withPortsMixin([
      containerPort.new("server-noscrape", 8300),
      containerPort.new("serf-noscrape", 8301),
      containerPort.new("client-noscrape", 8400),
      containerPort.new("http-noscrape", 8500),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  consul_deployment:
    deployment.new("consul", 1, [$.consul_container]),

  consul_service:
    $.util.serviceFor($.consul_deployment),
}
