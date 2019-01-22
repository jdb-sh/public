{
  local container = $.core.v1.container,

  alertmanager_container::
    container.new("alertmanager", $._images.alertmanager) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http-metrics", 80)
    ]) +
    container.withArgs([
      "-log.level=debug",
      "-server.http-listen-port=80",
      "-alertmanager.configs.url=http://configs.%(namespace)s.svc:80" % $._config,
      "-alertmanager.web.external-url=/api/prom/alertmanager",
    ]),

  local deployment = $.apps.v1beta1.deployment,

  alertmanager_deployment:
    deployment.new("alertmanager", 1, [$.alertmanager_container]),

  alertmanager_service:
    $.util.serviceFor($.alertmanager_deployment),
}
