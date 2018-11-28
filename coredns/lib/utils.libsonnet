local k = import "ksonnet-util/kausal.libsonnet";

k {
  // withAllowPrivilegeEscalation is not exposed in our version of k8s.libsonnet.
  // I want to use it and I don't want to have to work out the upgrade process.
  core+: {
    v1+: {
      container+:: {
        mixin+:: {
          securityContext+:: {
            local __securityContextMixin(securityContext) = { securityContext+: securityContext },
            withAllowPrivilegeEscalation(allowPrivilegeEscalation):: self +  __securityContextMixin({ allowPrivilegeEscalation: allowPrivilegeEscalation}),
          },
        },
      },
    },
  },
}
