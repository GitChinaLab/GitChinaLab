import * as types from './mutation_types';

export default {
  [types.SET_PATHS](state, paths) {
    state.baseBlobPath = paths.baseBlobPath;
    state.headBlobPath = paths.headBlobPath;
    state.reportsPath = paths.reportsPath;
    state.helpPath = paths.helpPath;
  },
  [types.REQUEST_REPORTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REPORTS_SUCCESS](state, data) {
    state.hasError = false;
    state.status = '';
    state.statusReason = '';
    state.isLoading = false;
    state.newIssues = data.newIssues;
    state.resolvedIssues = data.resolvedIssues;
  },
  [types.RECEIVE_REPORTS_ERROR](state, error) {
    state.isLoading = false;
    state.hasError = true;
    state.status = error?.status || '';
    state.statusReason = error?.response?.data?.status_reason;
  },
};
