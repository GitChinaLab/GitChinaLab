export const packageSettings = () => ({
  mavenDuplicatesAllowed: true,
  mavenDuplicateExceptionRegex: '',
  genericDuplicatesAllowed: true,
  genericDuplicateExceptionRegex: '',
});

export const dependencyProxySettings = (extend) => ({
  enabled: true,
  ...extend,
});

export const dependencyProxyImageTtlPolicy = (extend) => ({
  ttl: 90,
  enabled: true,
  ...extend,
});

export const groupPackageSettingsMock = {
  data: {
    group: {
      id: '1',
      fullPath: 'foo_group_path',
      packageSettings: packageSettings(),
      dependencyProxySetting: dependencyProxySettings(),
      dependencyProxyImageTtlPolicy: dependencyProxyImageTtlPolicy(),
    },
  },
};

export const groupPackageSettingsMutationMock = (override) => ({
  data: {
    updateNamespacePackageSettings: {
      packageSettings: {
        mavenDuplicatesAllowed: true,
        mavenDuplicateExceptionRegex: 'latest[main]something',
        genericDuplicatesAllowed: true,
        genericDuplicateExceptionRegex: 'latest[main]somethingGeneric',
      },
      errors: [],
      ...override,
    },
  },
});

export const dependencyProxySettingMutationMock = (override) => ({
  data: {
    updateDependencyProxySettings: {
      dependencyProxySetting: dependencyProxySettings(),
      errors: [],
      ...override,
    },
  },
});

export const dependencyProxyUpdateTllPolicyMutationMock = (override) => ({
  data: {
    updateDependencyProxyImageTtlGroupPolicy: {
      dependencyProxyImageTtlPolicy: dependencyProxyImageTtlPolicy(),
      errors: [],
      ...override,
    },
  },
});

export const groupPackageSettingsMutationErrorMock = {
  errors: [
    {
      message:
        'Variable $input of type UpdateNamespacePackageSettingsInput! was provided invalid value for mavenDuplicateExceptionRegex (latest[main]somethingj)) is an invalid regexp: unexpected ): latest[main]somethingj)))',
      locations: [{ line: 1, column: 41 }],
      extensions: {
        value: {
          namespacePath: 'gitlab-org',
          mavenDuplicateExceptionRegex: 'latest[main]something))',
        },
        problems: [
          {
            path: ['mavenDuplicateExceptionRegex'],
            explanation:
              'latest[main]somethingj)) is an invalid regexp: unexpected ): latest[main]something))',
            message:
              'latest[main]somethingj)) is an invalid regexp: unexpected ): latest[main]something))',
          },
        ],
      },
    },
  ],
};

export const mutationErrorMock = {
  errors: [
    {
      message: 'Some error',
      locations: [{ line: 1, column: 41 }],
      extensions: {
        value: {
          enabled: 'gitlab-org',
        },
        problems: [
          {
            path: ['enabled'],
            explanation: 'explaination',
            message: 'message',
          },
        ],
      },
    },
  ],
};
