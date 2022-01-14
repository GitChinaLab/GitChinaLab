import { s__ } from '~/locale';
import { stateToComponentMap as classStateMap, stateKey } from './stores/state_maps';

export const SUCCESS = 'success';
export const WARNING = 'warning';
export const DANGER = 'danger';
export const INFO = 'info';
export const CONFIRM = 'confirm';

export const MWPS_MERGE_STRATEGY = 'merge_when_pipeline_succeeds';
export const MTWPS_MERGE_STRATEGY = 'add_to_merge_train_when_pipeline_succeeds';
export const MT_MERGE_STRATEGY = 'merge_train';

export const PIPELINE_FAILED_STATE = 'failed';

export const AUTO_MERGE_STRATEGIES = [MWPS_MERGE_STRATEGY, MTWPS_MERGE_STRATEGY, MT_MERGE_STRATEGY];

// SP - "Suggest Pipelines"
export const SP_TRACK_LABEL = 'no_pipeline_noticed';
export const SP_SHOW_TRACK_EVENT = 'click_button';
export const SP_SHOW_TRACK_VALUE = 10;
export const SP_HELP_CONTENT = s__(
  `mrWidget|GitLab %{linkStart}CI/CD can automatically build, test, and deploy your application.%{linkEnd} It only takes a few minutes to get started, and we can help you create a pipeline configuration file.`,
);
export const SP_HELP_URL = 'https://docs.gitlab.com/ee/ci/quick_start/';
export const SP_ICON_NAME = 'status_notfound';

export const MERGE_ACTIVE_STATUS_PHRASES = [
  {
    message: s__('mrWidget|Merging! Drum roll, please…'),
    emoji: 'drum',
  },
  {
    message: s__("mrWidget|Merging! We're almost there…"),
    emoji: 'sparkles',
  },
  {
    message: s__('mrWidget|Merging! Changes will land soon…'),
    emoji: 'airplane_arriving',
  },
  {
    message: s__('mrWidget|Merging! Changes are being shipped…'),
    emoji: 'ship',
  },
  {
    message: s__("mrWidget|Merging! Everything's good…"),
    emoji: 'relieved',
  },
  {
    message: s__('mrWidget|Merging! This is going to be great…'),
    emoji: 'heart_eyes',
  },
  {
    message: s__('mrWidget|Merging! Lift-off in 5… 4… 3…'),
    emoji: 'rocket',
  },
  {
    message: s__('mrWidget|Merging! The changes are leaving the station…'),
    emoji: 'bullettrain_front',
  },
  {
    message: s__('mrWidget|Merging! Take a deep breath and relax…'),
    emoji: 'sunglasses',
  },
];

const STATE_MACHINE = {
  states: {
    IDLE: 'IDLE',
    MERGING: 'MERGING',
    AUTO_MERGE: 'AUTO_MERGE',
  },
  transitions: {
    MERGE: 'start-merge',
    AUTO_MERGE: 'start-auto-merge',
    MERGE_FAILURE: 'merge-failed',
    MERGED: 'merge-done',
  },
};
const { states, transitions } = STATE_MACHINE;

STATE_MACHINE.definition = {
  initial: states.IDLE,
  states: {
    [states.IDLE]: {
      on: {
        [transitions.MERGE]: states.MERGING,
        [transitions.AUTO_MERGE]: states.AUTO_MERGE,
      },
    },
    [states.MERGING]: {
      on: {
        [transitions.MERGED]: states.IDLE,
        [transitions.MERGE_FAILURE]: states.IDLE,
      },
    },
    [states.AUTO_MERGE]: {
      on: {
        [transitions.MERGED]: states.IDLE,
        [transitions.MERGE_FAILURE]: states.IDLE,
      },
    },
  },
};

export const stateToTransitionMap = {
  [stateKey.merging]: transitions.MERGE,
  [stateKey.merged]: transitions.MERGED,
  [stateKey.autoMergeEnabled]: transitions.AUTO_MERGE,
};
export const stateToComponentMap = {
  [states.MERGING]: classStateMap[stateKey.merging],
  [states.AUTO_MERGE]: classStateMap[stateKey.autoMergeEnabled],
};

export const EXTENSION_ICONS = {
  failed: 'failed',
  warning: 'warning',
  success: 'success',
  neutral: 'neutral',
  error: 'error',
  notice: 'notice',
  severityCritical: 'severityCritical',
  severityHigh: 'severityHigh',
  severityMedium: 'severityMedium',
  severityLow: 'severityLow',
  severityInfo: 'severityInfo',
  severityUnknown: 'severityUnknown',
};

export const EXTENSION_ICON_NAMES = {
  failed: 'status-failed',
  warning: 'status-alert',
  success: 'status-success',
  neutral: 'status-neutral',
  error: 'status-alert',
  notice: 'status-alert',
  severityCritical: 'severity-critical',
  severityHigh: 'severity-high',
  severityMedium: 'severity-medium',
  severityLow: 'severity-low',
  severityInfo: 'severity-info',
  severityUnknown: 'severity-unknown',
};

export const EXTENSION_ICON_CLASS = {
  failed: 'gl-text-red-500',
  warning: 'gl-text-orange-500',
  success: 'gl-text-green-500',
  neutral: 'gl-text-gray-400',
  error: 'gl-text-red-500',
  notice: 'gl-text-gray-500',
  severityCritical: 'gl-text-red-800',
  severityHigh: 'gl-text-red-600',
  severityMedium: 'gl-text-orange-400',
  severityLow: 'gl-text-orange-300',
  severityInfo: 'gl-text-blue-400',
  severityUnknown: 'gl-text-gray-400',
};

export const EXTENSION_SUMMARY_FAILED_CLASS = 'gl-text-red-500';
export const EXTENSION_SUMMARY_NEUTRAL_CLASS = 'gl-text-gray-700';

export { STATE_MACHINE };
