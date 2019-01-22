{
  local container = $.core.v1.container,

  memcached_container::
    container.new("memcached", $._images.memcached) +
    container.withArgs([
      "-m 64",
      "-p 11211",
    ]) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("clients", 11211),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  memcached_deployment:
    deployment.new("memcached", 1, [$.memcached_container]),

  memcached_service:
    $.util.serviceFor($.memcached_deployment),
}
