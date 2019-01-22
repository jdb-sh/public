{
  local container = $.core.v1.container,
  local readinessProbe = container.mixin.readinessProbe,

  ingester_container::
    container.new("ingester", $._images.ingester) +
    container.withArgs([
      "-ingester.join-after=30s",
      "-ingester.claim-on-rollout=false"] +
      $.util.mapToFlags($._config.common_args) +
      $.util.mapToFlags($._config.consul_args) +
      $.util.mapToFlags($._config.dynamodb_args) +
      $.util.mapToFlags($._config.memcached_args) +
      $.util.mapToFlags($._config.s3_args),
    ) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http", 80),
    ]) +
    readinessProbe.httpGet.withPath("/ready") +
    readinessProbe.httpGet.withPort(80) +
    readinessProbe.withInitialDelaySeconds(15) +
    readinessProbe.withTimeoutSeconds(1),

  local deployment = $.apps.v1beta1.deployment,

  ingester_deployment:
    deployment.new("ingester", 2, [$.ingester_container]) +
    deployment.mixin.spec.withMinReadySeconds(60) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxSurge(0) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxUnavailable(1) +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(2400),

  ingester_service:
    $.util.serviceFor($.ingester_deployment),
}
