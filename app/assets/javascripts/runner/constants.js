import { s__ } from '~/locale';

export const RUNNER_PAGE_SIZE = 20;
export const RUNNER_JOB_COUNT_LIMIT = 1000;
export const GROUP_RUNNER_COUNT_LIMIT = 1000;

export const I18N_FETCH_ERROR = s__('Runners|Something went wrong while fetching runner data.');
export const I18N_DETAILS_TITLE = s__('Runners|Runner #%{runner_id}');

// Type
export const I18N_INSTANCE_RUNNER_DESCRIPTION = s__('Runners|Available to all projects');
export const I18N_GROUP_RUNNER_DESCRIPTION = s__(
  'Runners|Available to all projects and subgroups in the group',
);
export const I18N_PROJECT_RUNNER_DESCRIPTION = s__('Runners|Associated with one or more projects');

// Status
export const I18N_ONLINE_RUNNER_TIMEAGO_DESCRIPTION = s__(
  'Runners|Runner is online; last contact was %{timeAgo}',
);
export const I18N_NOT_CONNECTED_RUNNER_DESCRIPTION = s__(
  'Runners|This runner has never connected to this instance',
);
export const I18N_OFFLINE_RUNNER_TIMEAGO_DESCRIPTION = s__(
  'Runners|No recent contact from this runner; last contact was %{timeAgo}',
);
export const I18N_STALE_RUNNER_DESCRIPTION = s__(
  'Runners|No contact from this runner in over 3 months',
);

export const I18N_LOCKED_RUNNER_DESCRIPTION = s__('Runners|You cannot assign to other projects');
export const I18N_PAUSED_RUNNER_DESCRIPTION = s__('Runners|Not available to run jobs');

export const RUNNER_TAG_BADGE_VARIANT = 'neutral';
export const RUNNER_TAG_BG_CLASS = 'gl-bg-blue-100';

// Filtered search parameter names
// - Used for URL params names
// - GlFilteredSearch tokens type

export const PARAM_KEY_STATUS = 'status';
export const PARAM_KEY_RUNNER_TYPE = 'runner_type';
export const PARAM_KEY_TAG = 'tag';
export const PARAM_KEY_SEARCH = 'search';

export const PARAM_KEY_SORT = 'sort';
export const PARAM_KEY_PAGE = 'page';
export const PARAM_KEY_AFTER = 'after';
export const PARAM_KEY_BEFORE = 'before';

// CiRunnerType

export const INSTANCE_TYPE = 'INSTANCE_TYPE';
export const GROUP_TYPE = 'GROUP_TYPE';
export const PROJECT_TYPE = 'PROJECT_TYPE';

// CiRunnerStatus

export const STATUS_ACTIVE = 'ACTIVE';
export const STATUS_PAUSED = 'PAUSED';

export const STATUS_ONLINE = 'ONLINE';
export const STATUS_NOT_CONNECTED = 'NOT_CONNECTED';
export const STATUS_NEVER_CONTACTED = 'NEVER_CONTACTED';
export const STATUS_OFFLINE = 'OFFLINE';
export const STATUS_STALE = 'STALE';

// CiRunnerAccessLevel

export const ACCESS_LEVEL_NOT_PROTECTED = 'NOT_PROTECTED';
export const ACCESS_LEVEL_REF_PROTECTED = 'REF_PROTECTED';

// CiRunnerSort

export const CREATED_DESC = 'CREATED_DESC';
export const CREATED_ASC = 'CREATED_ASC'; // TODO Add this to the API
export const CONTACTED_DESC = 'CONTACTED_DESC'; // TODO Add this to the API
export const CONTACTED_ASC = 'CONTACTED_ASC';

export const DEFAULT_SORT = CREATED_DESC;

// Local storage namespaces

export const ADMIN_FILTERED_SEARCH_NAMESPACE = 'admin_runners';
export const GROUP_FILTERED_SEARCH_NAMESPACE = 'group_runners';
