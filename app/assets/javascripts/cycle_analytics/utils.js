import { hideFlash } from '~/flash';
import { parseSeconds } from '~/lib/utils/datetime_utility';
import { formatTimeAsSummary } from '~/lib/utils/datetime/date_format_utility';
import { slugify } from '~/lib/utils/text_utility';

export const removeFlash = (type = 'alert') => {
  const flashEl = document.querySelector(`.flash-${type}`);
  if (flashEl) {
    hideFlash(flashEl);
  }
};

/**
 * Takes the stages and median data, combined with the selected stage, to build an
 * array which is formatted to proivde the data required for the path navigation.
 *
 * @param {Array} stages - The stages available to the group / project
 * @param {Object} medians - The median values for the stages available to the group / project
 * @param {Object} stageCounts - The total item count for the stages available
 * @param {Object} selectedStage - The currently selected stage
 * @returns {Array} An array of stages formatted with data required for the path navigation
 */
export const transformStagesForPathNavigation = ({
  stages,
  medians,
  stageCounts = {},
  selectedStage,
}) => {
  const formattedStages = stages.map((stage) => {
    return {
      metric: medians[stage?.id],
      selected: stage?.id === selectedStage?.id, // Also could null === null cause an issue here?
      stageCount: stageCounts && stageCounts[stage?.id],
      icon: null,
      ...stage,
    };
  });

  return formattedStages;
};

/**
 * Takes a raw median value in seconds and converts it to a string representation
 * ie. converts 172800 => 2d (2 days)
 *
 * @param {Number} Median - The number of seconds for the median calculation
 * @returns {String} String representation ie 2w
 */
export const medianTimeToParsedSeconds = (value) =>
  formatTimeAsSummary({
    ...parseSeconds(value, { daysPerWeek: 7, hoursPerDay: 24 }),
    seconds: value,
  });

/**
 * Takes the raw median value arrays and converts them into a useful object
 * containing the string for display in the path navigation
 * ie. converts [{ id: 'test', value: 172800 }] => { 'test': '2d' }
 *
 * @param {Array} Medians - Array of stage median objects, each contains a `id`, `value` and `error`
 * @returns {Object} Returns key value pair with the stage name and its display median value
 */
export const formatMedianValues = (medians = []) =>
  medians.reduce((acc, { id, value = 0 }) => {
    return {
      ...acc,
      [id]: value ? medianTimeToParsedSeconds(value) : '-',
    };
  }, {});

export const filterStagesByHiddenStatus = (stages = [], isHidden = true) =>
  stages.filter(({ hidden = false }) => hidden === isHidden);

/**
 * @typedef {Object} MetricData
 * @property {String} title - Title of the metric measured
 * @property {String} value - String representing the decimal point value, e.g '1.5'
 * @property {String} [unit] - String representing the decimal point value, e.g '1.5'
 *
 * @typedef {Object} TransformedMetricData
 * @property {String} label - Title of the metric measured
 * @property {String} value - String representing the decimal point value, e.g '1.5'
 * @property {String} key - Slugified string based on the 'title'
 * @property {String} description - String to display for a description
 * @property {String} unit - String representing the decimal point value, e.g '1.5'
 */

/**
 * Prepares metric data to be rendered in the metric_card component
 *
 * @param {MetricData[]} data - The metric data to be rendered
 * @param {Object} popoverContent - Key value pair of data to display in the popover
 * @returns {TransformedMetricData[]} An array of metrics ready to render in the metric_card
 */

export const prepareTimeMetricsData = (data = [], popoverContent = {}) =>
  data.map(({ title: label, ...rest }) => {
    const key = slugify(label);
    return {
      ...rest,
      label,
      key,
      description: popoverContent[key]?.description || '',
    };
  });

const extractFeatures = (gon) => ({
  cycleAnalyticsForGroups: Boolean(gon?.licensed_features?.cycleAnalyticsForGroups),
});

/**
 * Builds the initial data object for Value Stream Analytics with data loaded from the backend
 *
 * @param {Object} dataset - dataset object paseed to the frontend via data-* properties
 * @returns {Object} - The initial data to load the app with
 */
export const buildCycleAnalyticsInitialData = ({
  fullPath,
  requestPath,
  projectId,
  groupId,
  groupPath,
  labelsPath,
  milestonesPath,
  stage,
  createdAfter,
  createdBefore,
  gon,
} = {}) => {
  return {
    projectId: parseInt(projectId, 10),
    endpoints: {
      requestPath,
      fullPath,
      labelsPath,
      milestonesPath,
      groupId: parseInt(groupId, 10),
      groupPath,
    },
    createdAfter: new Date(createdAfter),
    createdBefore: new Date(createdBefore),
    selectedStage: stage ? JSON.parse(stage) : null,
    features: extractFeatures(gon),
  };
};
