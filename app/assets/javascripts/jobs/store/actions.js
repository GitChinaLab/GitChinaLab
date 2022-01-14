import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { setFaviconOverlay, resetFavicon } from '~/lib/utils/favicon';
import httpStatusCodes from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import {
  canScroll,
  isScrolledToBottom,
  isScrolledToTop,
  isScrolledToMiddle,
  scrollDown,
  scrollUp,
} from '~/lib/utils/scroll_utils';
import { __ } from '~/locale';
import { reportToSentry } from '../utils';
import * as types from './mutation_types';

export const init = ({ dispatch }, { endpoint, logState, pagePath }) => {
  dispatch('setJobEndpoint', endpoint);
  dispatch('setJobLogOptions', {
    logState,
    pagePath,
  });

  return Promise.all([dispatch('fetchJob'), dispatch('fetchJobLog')]);
};

export const setJobEndpoint = ({ commit }, endpoint) => commit(types.SET_JOB_ENDPOINT, endpoint);
export const setJobLogOptions = ({ commit }, options) => commit(types.SET_JOB_LOG_OPTIONS, options);

export const hideSidebar = ({ commit }) => commit(types.HIDE_SIDEBAR);
export const showSidebar = ({ commit }) => commit(types.SHOW_SIDEBAR);

export const toggleSidebar = ({ dispatch, state }) => {
  if (state.isSidebarOpen) {
    dispatch('hideSidebar');
  } else {
    dispatch('showSidebar');
  }
};

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};

export const stopPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

export const restartPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const requestJob = ({ commit }) => commit(types.REQUEST_JOB);

export const fetchJob = ({ state, dispatch }) => {
  dispatch('requestJob');

  eTagPoll = new Poll({
    resource: {
      getJob(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.jobEndpoint,
    method: 'getJob',
    successCallback: ({ data }) => dispatch('receiveJobSuccess', data),
    errorCallback: () => dispatch('receiveJobError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.jobEndpoint)
      .then(({ data }) => dispatch('receiveJobSuccess', data))
      .catch(() => dispatch('receiveJobError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveJobSuccess = ({ commit }, data = {}) => {
  commit(types.RECEIVE_JOB_SUCCESS, data);

  if (data.status && data.status.favicon) {
    setFaviconOverlay(data.status.favicon);
  } else {
    resetFavicon();
  }
};
export const receiveJobError = ({ commit }) => {
  commit(types.RECEIVE_JOB_ERROR);
  createFlash({
    message: __('An error occurred while fetching the job.'),
  });
  resetFavicon();
};

/**
 * Job Log
 */
export const scrollTop = ({ dispatch }) => {
  scrollUp();
  dispatch('toggleScrollButtons');
};

export const scrollBottom = ({ dispatch }) => {
  scrollDown();
  dispatch('toggleScrollButtons');
};

/**
 * Responsible for toggling the disabled state of the scroll buttons
 */
export const toggleScrollButtons = ({ dispatch }) => {
  if (canScroll()) {
    if (isScrolledToMiddle()) {
      dispatch('enableScrollTop');
      dispatch('enableScrollBottom');
    } else if (isScrolledToTop()) {
      dispatch('disableScrollTop');
      dispatch('enableScrollBottom');
    } else if (isScrolledToBottom()) {
      dispatch('disableScrollBottom');
      dispatch('enableScrollTop');
    }
  } else {
    dispatch('disableScrollBottom');
    dispatch('disableScrollTop');
  }
};

export const disableScrollBottom = ({ commit }) => commit(types.DISABLE_SCROLL_BOTTOM);
export const disableScrollTop = ({ commit }) => commit(types.DISABLE_SCROLL_TOP);
export const enableScrollBottom = ({ commit }) => commit(types.ENABLE_SCROLL_BOTTOM);
export const enableScrollTop = ({ commit }) => commit(types.ENABLE_SCROLL_TOP);

/**
 * While the automatic scroll down is active,
 * we show the scroll down button with an animation
 */
export const toggleScrollAnimation = ({ commit }, toggle) =>
  commit(types.TOGGLE_SCROLL_ANIMATION, toggle);

/**
 * Responsible to handle automatic scroll
 */
export const toggleScrollisInBottom = ({ commit }, toggle) => {
  commit(types.TOGGLE_IS_SCROLL_IN_BOTTOM_BEFORE_UPDATING_JOB_LOG, toggle);
};

export const requestJobLog = ({ commit }) => commit(types.REQUEST_JOB_LOG);

export const fetchJobLog = ({ dispatch, state }) =>
  // update trace endpoint once BE compeletes trace re-naming in #340626
  axios
    .get(`${state.jobLogEndpoint}/trace.json`, {
      params: { state: state.jobLogState },
    })
    .then(({ data }) => {
      dispatch('toggleScrollisInBottom', isScrolledToBottom());
      dispatch('receiveJobLogSuccess', data);

      if (data.complete) {
        dispatch('stopPollingJobLog');
      } else if (!state.jobLogTimeout) {
        dispatch('startPollingJobLog');
      }
    })
    .catch((e) => {
      if (e.response.status === httpStatusCodes.FORBIDDEN) {
        dispatch('receiveJobLogUnauthorizedError');
      } else {
        reportToSentry('job_actions', e);
        dispatch('receiveJobLogError');
      }
    });

export const startPollingJobLog = ({ dispatch, commit }) => {
  const jobLogTimeout = setTimeout(() => {
    commit(types.SET_JOB_LOG_TIMEOUT, 0);
    dispatch('fetchJobLog');
  }, 4000);

  commit(types.SET_JOB_LOG_TIMEOUT, jobLogTimeout);
};

export const stopPollingJobLog = ({ state, commit }) => {
  clearTimeout(state.jobLogTimeout);
  commit(types.SET_JOB_LOG_TIMEOUT, 0);
  commit(types.STOP_POLLING_JOB_LOG);
};

export const receiveJobLogSuccess = ({ commit }, log) => commit(types.RECEIVE_JOB_LOG_SUCCESS, log);

export const receiveJobLogError = ({ dispatch }) => {
  dispatch('stopPollingJobLog');
  createFlash({
    message: __('An error occurred while fetching the job log.'),
  });
};

export const receiveJobLogUnauthorizedError = ({ dispatch }) => {
  dispatch('stopPollingJobLog');
  createFlash({
    message: __('The current user is not authorized to access the job log.'),
  });
};
/**
 * When the user clicks a collapsible line in the job
 * log, we commit a mutation to update the state
 *
 * @param {Object} section
 */
export const toggleCollapsibleLine = ({ commit }, section) =>
  commit(types.TOGGLE_COLLAPSIBLE_LINE, section);

/**
 * Jobs list on sidebar - depend on stages dropdown
 */
export const requestJobsForStage = ({ commit }, stage) =>
  commit(types.REQUEST_JOBS_FOR_STAGE, stage);

// On stage click, set selected stage + fetch job
export const fetchJobsForStage = ({ dispatch }, stage = {}) => {
  dispatch('requestJobsForStage', stage);

  axios
    .get(stage.dropdown_path, {
      params: {
        retried: 1,
      },
    })
    .then(({ data }) => {
      const retriedJobs = data.retried.map((job) => ({ ...job, retried: true }));
      const jobs = data.latest_statuses.concat(retriedJobs);

      dispatch('receiveJobsForStageSuccess', jobs);
    })
    .catch(() => dispatch('receiveJobsForStageError'));
};
export const receiveJobsForStageSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_JOBS_FOR_STAGE_SUCCESS, data);

export const receiveJobsForStageError = ({ commit }) => {
  commit(types.RECEIVE_JOBS_FOR_STAGE_ERROR);
  createFlash({
    message: __('An error occurred while fetching the jobs.'),
  });
};

export const triggerManualJob = ({ state }, variables) => {
  const parsedVariables = variables.map((variable) => {
    const copyVar = { ...variable };
    delete copyVar.id;
    return copyVar;
  });

  axios
    .post(state.job.status.action.path, {
      job_variables_attributes: parsedVariables,
    })
    .catch(() =>
      createFlash({
        message: __('An error occurred while triggering the job.'),
      }),
    );
};
