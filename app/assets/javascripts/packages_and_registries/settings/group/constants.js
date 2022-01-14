import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';

export const PACKAGE_SETTINGS_HEADER = s__('PackageRegistry|Package Registry');
export const PACKAGE_SETTINGS_DESCRIPTION = s__(
  'PackageRegistry|Use GitLab as a private registry for common package formats. %{linkStart}Learn more.%{linkEnd}',
);

export const DUPLICATES_TOGGLE_LABEL = s__('PackageRegistry|Allow duplicates');
export const DUPLICATES_ALLOWED_DISABLED = s__(
  'PackageRegistry|%{boldStart}Do not allow duplicates%{boldEnd} - Reject packages with the same name and version.',
);
export const DUPLICATES_ALLOWED_ENABLED = s__(
  'PackageRegistry|%{boldStart}Allow duplicates%{boldEnd} - Accept packages with the same name and version.',
);
export const DUPLICATES_SETTING_EXCEPTION_TITLE = __('Exceptions');
export const DUPLICATES_SETTINGS_EXCEPTION_LEGEND = s__(
  'PackageRegistry|Publish packages if their name or version matches this regex.',
);

export const DEPENDENCY_PROXY_HEADER = s__('DependencyProxy|Dependency Proxy');
export const DEPENDENCY_PROXY_SETTINGS_DESCRIPTION = s__(
  'DependencyProxy|Create a local proxy for storing frequently used upstream images. %{docLinkStart}Learn more%{docLinkEnd} about dependency proxies.',
);

// Parameters

export const PACKAGES_DOCS_PATH = helpPagePath('user/packages');
export const MAVEN_DUPLICATES_ALLOWED = 'mavenDuplicatesAllowed';
export const MAVEN_DUPLICATE_EXCEPTION_REGEX = 'mavenDuplicateExceptionRegex';

export const DEPENDENCY_PROXY_DOCS_PATH = helpPagePath('user/packages/dependency_proxy/index');
