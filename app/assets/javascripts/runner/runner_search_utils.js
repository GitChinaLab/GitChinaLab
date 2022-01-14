import { queryToObject, setUrlParams } from '~/lib/utils/url_utility';
import {
  filterToQueryObject,
  processFilters,
  urlQueryToFilter,
  prepareTokens,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import {
  PARAM_KEY_STATUS,
  PARAM_KEY_RUNNER_TYPE,
  PARAM_KEY_TAG,
  PARAM_KEY_SEARCH,
  PARAM_KEY_SORT,
  PARAM_KEY_PAGE,
  PARAM_KEY_AFTER,
  PARAM_KEY_BEFORE,
  DEFAULT_SORT,
  RUNNER_PAGE_SIZE,
} from './constants';

/**
 * The filters and sorting of the runners are built around
 * an object called "search" that contains the current state
 * of search in the UI. For example:
 *
 * ```
 * const search = {
 *   // The current tab
 *   runnerType: 'INSTANCE_TYPE',
 *
 *   // Filters in the search bar
 *   filters: [
 *     { type: 'status', value: { data: 'ACTIVE', operator: '=' } },
 *     { type: 'filtered-search-term', value: { data: '' } },
 *   ],
 *
 *   // Current sorting value
 *   sort: 'CREATED_DESC',
 *
 *   // Pagination information
 *   pagination: { page: 1 },
 * };
 * ```
 *
 * An object in this format can be used to generate URLs
 * with the search parameters or by runner components
 * a input using a v-model.
 *
 * @module runner_search_utils
 */

/**
 * Validates a search value
 * @param {Object} search
 * @returns {boolean} True if the value follows the search format.
 */
export const searchValidator = ({ runnerType, filters, sort }) => {
  return (
    (runnerType === null || typeof runnerType === 'string') &&
    Array.isArray(filters) &&
    typeof sort === 'string'
  );
};

const getPaginationFromParams = (params) => {
  const page = parseInt(params[PARAM_KEY_PAGE], 10);
  const after = params[PARAM_KEY_AFTER];
  const before = params[PARAM_KEY_BEFORE];

  if (page && (before || after)) {
    return {
      page,
      before,
      after,
    };
  }
  return {
    page: 1,
  };
};

/**
 * Takes a URL query and transforms it into a "search" object
 * @param {String?} query
 * @returns {Object} A search object
 */
export const fromUrlQueryToSearch = (query = window.location.search) => {
  const params = queryToObject(query, { gatherArrays: true });
  const runnerType = params[PARAM_KEY_RUNNER_TYPE]?.[0] || null;

  return {
    runnerType,
    filters: prepareTokens(
      urlQueryToFilter(query, {
        filterNamesAllowList: [PARAM_KEY_STATUS, PARAM_KEY_TAG],
        filteredSearchTermKey: PARAM_KEY_SEARCH,
      }),
    ),
    sort: params[PARAM_KEY_SORT] || DEFAULT_SORT,
    pagination: getPaginationFromParams(params),
  };
};

/**
 * Takes a "search" object and transforms it into a URL.
 *
 * @param {Object} search
 * @param {String} url
 * @returns {String} New URL for the page
 */
export const fromSearchToUrl = (
  { runnerType = null, filters = [], sort = null, pagination = {} },
  url = window.location.href,
) => {
  const filterParams = {
    // Defaults
    [PARAM_KEY_STATUS]: [],
    [PARAM_KEY_RUNNER_TYPE]: [],
    [PARAM_KEY_TAG]: [],
    // Current filters
    ...filterToQueryObject(processFilters(filters), {
      filteredSearchTermKey: PARAM_KEY_SEARCH,
    }),
  };

  if (runnerType) {
    filterParams[PARAM_KEY_RUNNER_TYPE] = [runnerType];
  }

  if (!filterParams[PARAM_KEY_SEARCH]) {
    filterParams[PARAM_KEY_SEARCH] = null;
  }

  const isDefaultSort = sort !== DEFAULT_SORT;
  const isFirstPage = pagination?.page === 1;
  const otherParams = {
    // Sorting & Pagination
    [PARAM_KEY_SORT]: isDefaultSort ? sort : null,
    [PARAM_KEY_PAGE]: isFirstPage ? null : pagination.page,
    [PARAM_KEY_BEFORE]: isFirstPage ? null : pagination.before,
    [PARAM_KEY_AFTER]: isFirstPage ? null : pagination.after,
  };

  return setUrlParams({ ...filterParams, ...otherParams }, url, false, true, true);
};

/**
 * Takes a "search" object and transforms it into variables for runner a GraphQL query.
 *
 * @param {Object} search
 * @returns {Object} Hash of filter values
 */
export const fromSearchToVariables = ({
  runnerType = null,
  filters = [],
  sort = null,
  pagination = {},
} = {}) => {
  const variables = {};

  const queryObj = filterToQueryObject(processFilters(filters), {
    filteredSearchTermKey: PARAM_KEY_SEARCH,
  });

  [variables.status] = queryObj[PARAM_KEY_STATUS] || [];
  variables.search = queryObj[PARAM_KEY_SEARCH];
  variables.tagList = queryObj[PARAM_KEY_TAG];

  if (runnerType) {
    variables.type = runnerType;
  }
  if (sort) {
    variables.sort = sort;
  }

  if (pagination.before) {
    variables.before = pagination.before;
    variables.last = RUNNER_PAGE_SIZE;
  } else {
    variables.after = pagination.after;
    variables.first = RUNNER_PAGE_SIZE;
  }

  return variables;
};
