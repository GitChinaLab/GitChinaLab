import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SAST_IAC,
  REPORT_TYPE_DAST,
  REPORT_TYPE_DAST_PROFILES,
  REPORT_TYPE_SECRET_DETECTION,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
  REPORT_TYPE_CLUSTER_IMAGE_SCANNING,
  REPORT_TYPE_COVERAGE_FUZZING,
  REPORT_TYPE_CORPUS_MANAGEMENT,
  REPORT_TYPE_API_FUZZING,
  REPORT_TYPE_LICENSE_COMPLIANCE,
} from '~/vue_shared/security_reports/constants';

import configureSastMutation from '../graphql/configure_sast.mutation.graphql';
import configureSastIacMutation from '../graphql/configure_iac.mutation.graphql';
import configureSecretDetectionMutation from '../graphql/configure_secret_detection.mutation.graphql';

/**
 * Translations & helpPagePaths for Security Configuration Page
 * Make sure to add new scanner translations to the SCANNER_NAMES_MAP below.
 */

export const SAST_NAME = __('Static Application Security Testing (SAST)');
export const SAST_SHORT_NAME = s__('ciReport|SAST');
export const SAST_DESCRIPTION = __('Analyze your source code for known vulnerabilities.');
export const SAST_HELP_PATH = helpPagePath('user/application_security/sast/index');
export const SAST_CONFIG_HELP_PATH = helpPagePath('user/application_security/sast/index', {
  anchor: 'configuration',
});

export const SAST_IAC_NAME = __('Infrastructure as Code (IaC) Scanning');
export const SAST_IAC_SHORT_NAME = s__('ciReport|IaC Scanning');
export const SAST_IAC_DESCRIPTION = __(
  'Analyze your infrastructure as code configuration files for known vulnerabilities.',
);
export const SAST_IAC_HELP_PATH = helpPagePath('user/application_security/iac_scanning/index');
export const SAST_IAC_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/iac_scanning/index',
  {
    anchor: 'configuration',
  },
);

export const DAST_NAME = __('Dynamic Application Security Testing (DAST)');
export const DAST_SHORT_NAME = s__('ciReport|DAST');
export const DAST_DESCRIPTION = __('Analyze a review version of your web application.');
export const DAST_HELP_PATH = helpPagePath('user/application_security/dast/index');
export const DAST_CONFIG_HELP_PATH = helpPagePath('user/application_security/dast/index', {
  anchor: 'enable-dast',
});

export const DAST_PROFILES_NAME = __('DAST Scans');
export const DAST_PROFILES_DESCRIPTION = s__(
  'SecurityConfiguration|Manage profiles for use by DAST scans.',
);
export const DAST_PROFILES_HELP_PATH = helpPagePath('user/application_security/dast/index');
export const DAST_PROFILES_CONFIG_TEXT = s__('SecurityConfiguration|Manage scans');

export const SECRET_DETECTION_NAME = __('Secret Detection');
export const SECRET_DETECTION_DESCRIPTION = __(
  'Analyze your source code and git history for secrets.',
);
export const SECRET_DETECTION_HELP_PATH = helpPagePath(
  'user/application_security/secret_detection/index',
);
export const SECRET_DETECTION_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/secret_detection/index',
  { anchor: 'configuration' },
);

export const DEPENDENCY_SCANNING_NAME = __('Dependency Scanning');
export const DEPENDENCY_SCANNING_DESCRIPTION = __(
  'Analyze your dependencies for known vulnerabilities.',
);
export const DEPENDENCY_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/dependency_scanning/index',
);
export const DEPENDENCY_SCANNING_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/dependency_scanning/index',
  { anchor: 'configuration' },
);

export const CONTAINER_SCANNING_NAME = __('Container Scanning');
export const CONTAINER_SCANNING_DESCRIPTION = __(
  'Check your Docker images for known vulnerabilities.',
);
export const CONTAINER_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/container_scanning/index',
);
export const CONTAINER_SCANNING_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/container_scanning/index',
  { anchor: 'configuration' },
);

export const CLUSTER_IMAGE_SCANNING_NAME = s__('ciReport|Cluster Image Scanning');
export const CLUSTER_IMAGE_SCANNING_DESCRIPTION = __(
  'Check your Kubernetes cluster images for known vulnerabilities.',
);
export const CLUSTER_IMAGE_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/cluster_image_scanning/index',
);
export const CLUSTER_IMAGE_SCANNING_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/cluster_image_scanning/index',
  { anchor: 'configuration' },
);

export const COVERAGE_FUZZING_NAME = __('Coverage Fuzzing');
export const COVERAGE_FUZZING_DESCRIPTION = __(
  'Find bugs in your code with coverage-guided fuzzing.',
);
export const COVERAGE_FUZZING_HELP_PATH = helpPagePath(
  'user/application_security/coverage_fuzzing/index',
);
export const COVERAGE_FUZZING_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/coverage_fuzzing/index',
  { anchor: 'configuration' },
);

export const CORPUS_MANAGEMENT_NAME = __('Corpus Management');
export const CORPUS_MANAGEMENT_DESCRIPTION = s__(
  'SecurityConfiguration|Manage corpus files used as mutation sources in coverage fuzzing.',
);
export const CORPUS_MANAGEMENT_CONFIG_TEXT = s__('SecurityConfiguration|Manage corpus');

export const API_FUZZING_NAME = __('API Fuzzing');
export const API_FUZZING_DESCRIPTION = __('Find bugs in your code with API fuzzing.');
export const API_FUZZING_HELP_PATH = helpPagePath('user/application_security/api_fuzzing/index');

export const LICENSE_COMPLIANCE_NAME = __('License Compliance');
export const LICENSE_COMPLIANCE_DESCRIPTION = __(
  'Search your project dependencies for their licenses and apply policies.',
);
export const LICENSE_COMPLIANCE_HELP_PATH = helpPagePath(
  'user/compliance/license_compliance/index',
);

export const SCANNER_NAMES_MAP = {
  SAST: SAST_SHORT_NAME,
  SAST_IAC: SAST_IAC_NAME,
  DAST: DAST_SHORT_NAME,
  API_FUZZING: API_FUZZING_NAME,
  CONTAINER_SCANNING: CONTAINER_SCANNING_NAME,
  CLUSTER_IMAGE_SCANNING: CLUSTER_IMAGE_SCANNING_NAME,
  COVERAGE_FUZZING: COVERAGE_FUZZING_NAME,
  SECRET_DETECTION: SECRET_DETECTION_NAME,
  DEPENDENCY_SCANNING: DEPENDENCY_SCANNING_NAME,
};

export const securityFeatures = [
  {
    name: SAST_NAME,
    shortName: SAST_SHORT_NAME,
    description: SAST_DESCRIPTION,
    helpPath: SAST_HELP_PATH,
    configurationHelpPath: SAST_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SAST,
    // This field is currently hardcoded because SAST is always available.
    // It will eventually come from the Backend, the progress is tracked in
    // https://gitlab.com/gitlab-org/gitlab/-/issues/331622
    available: true,

    // This field is currently hardcoded because SAST can always be enabled via MR
    // It will eventually come from the Backend, the progress is tracked in
    // https://gitlab.com/gitlab-org/gitlab/-/issues/331621
    canEnableByMergeRequest: true,
  },
  {
    name: SAST_IAC_NAME,
    shortName: SAST_IAC_SHORT_NAME,
    description: SAST_IAC_DESCRIPTION,
    helpPath: SAST_IAC_HELP_PATH,
    configurationHelpPath: SAST_IAC_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SAST_IAC,

    // This field is currently hardcoded because SAST IaC is always available.
    // It will eventually come from the Backend, the progress is tracked in
    // https://gitlab.com/gitlab-org/gitlab/-/issues/331622
    available: true,

    // This field will eventually come from the backend, the progress is
    // tracked in https://gitlab.com/gitlab-org/gitlab/-/issues/331621
    canEnableByMergeRequest: true,
  },
  {
    name: DAST_NAME,
    shortName: DAST_SHORT_NAME,
    description: DAST_DESCRIPTION,
    helpPath: DAST_HELP_PATH,
    configurationHelpPath: DAST_CONFIG_HELP_PATH,
    type: REPORT_TYPE_DAST,
    secondary: {
      type: REPORT_TYPE_DAST_PROFILES,
      name: DAST_PROFILES_NAME,
      description: DAST_PROFILES_DESCRIPTION,
      configurationText: DAST_PROFILES_CONFIG_TEXT,
    },
  },
  {
    name: DEPENDENCY_SCANNING_NAME,
    description: DEPENDENCY_SCANNING_DESCRIPTION,
    helpPath: DEPENDENCY_SCANNING_HELP_PATH,
    configurationHelpPath: DEPENDENCY_SCANNING_CONFIG_HELP_PATH,
    type: REPORT_TYPE_DEPENDENCY_SCANNING,

    // This field will eventually come from the backend, the progress is
    // tracked in https://gitlab.com/gitlab-org/gitlab/-/issues/331621
    canEnableByMergeRequest: true,
  },
  {
    name: CONTAINER_SCANNING_NAME,
    description: CONTAINER_SCANNING_DESCRIPTION,
    helpPath: CONTAINER_SCANNING_HELP_PATH,
    configurationHelpPath: CONTAINER_SCANNING_CONFIG_HELP_PATH,
    type: REPORT_TYPE_CONTAINER_SCANNING,
  },
  {
    name: CLUSTER_IMAGE_SCANNING_NAME,
    description: CLUSTER_IMAGE_SCANNING_DESCRIPTION,
    helpPath: CLUSTER_IMAGE_SCANNING_HELP_PATH,
    configurationHelpPath: CLUSTER_IMAGE_SCANNING_CONFIG_HELP_PATH,
    type: REPORT_TYPE_CLUSTER_IMAGE_SCANNING,
  },
  {
    name: SECRET_DETECTION_NAME,
    description: SECRET_DETECTION_DESCRIPTION,
    helpPath: SECRET_DETECTION_HELP_PATH,
    configurationHelpPath: SECRET_DETECTION_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SECRET_DETECTION,

    // This field is currently hardcoded because Secret Detection is always
    // available.  It will eventually come from the Backend, the progress is
    // tracked in https://gitlab.com/gitlab-org/gitlab/-/issues/333113
    available: true,

    // This field is currently hardcoded because SAST can always be enabled via MR
    // It will eventually come from the Backend, the progress is tracked in
    // https://gitlab.com/gitlab-org/gitlab/-/issues/331621
    canEnableByMergeRequest: true,
  },
  {
    name: API_FUZZING_NAME,
    description: API_FUZZING_DESCRIPTION,
    helpPath: API_FUZZING_HELP_PATH,
    type: REPORT_TYPE_API_FUZZING,
  },
  {
    name: COVERAGE_FUZZING_NAME,
    description: COVERAGE_FUZZING_DESCRIPTION,
    helpPath: COVERAGE_FUZZING_HELP_PATH,
    configurationHelpPath: COVERAGE_FUZZING_CONFIG_HELP_PATH,
    type: REPORT_TYPE_COVERAGE_FUZZING,
    secondary: gon?.features?.corpusManagement
      ? {
          type: REPORT_TYPE_CORPUS_MANAGEMENT,
          name: CORPUS_MANAGEMENT_NAME,
          description: CORPUS_MANAGEMENT_DESCRIPTION,
          configurationText: CORPUS_MANAGEMENT_CONFIG_TEXT,
        }
      : {},
  },
];

export const complianceFeatures = [
  {
    name: LICENSE_COMPLIANCE_NAME,
    description: LICENSE_COMPLIANCE_DESCRIPTION,
    helpPath: LICENSE_COMPLIANCE_HELP_PATH,
    type: REPORT_TYPE_LICENSE_COMPLIANCE,
  },
];

export const featureToMutationMap = {
  [REPORT_TYPE_SAST]: {
    mutationId: 'configureSast',
    getMutationPayload: (projectPath) => ({
      mutation: configureSastMutation,
      variables: {
        input: {
          projectPath,
          configuration: { global: [], pipeline: [], analyzers: [] },
        },
      },
    }),
  },
  [REPORT_TYPE_SAST_IAC]: {
    mutationId: 'configureSastIac',
    getMutationPayload: (projectPath) => ({
      mutation: configureSastIacMutation,
      variables: {
        input: {
          projectPath,
        },
      },
    }),
  },
  [REPORT_TYPE_SECRET_DETECTION]: {
    mutationId: 'configureSecretDetection',
    getMutationPayload: (projectPath) => ({
      mutation: configureSecretDetectionMutation,
      variables: {
        input: {
          projectPath,
        },
      },
    }),
  },
};

export const AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY =
  'security_configuration_auto_devops_enabled_dismissed_projects';
