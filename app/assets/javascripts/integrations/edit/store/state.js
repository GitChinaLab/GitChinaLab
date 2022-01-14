export default ({ defaultState = null, customState = {} } = {}) => {
  const override = defaultState !== null ? defaultState.id !== customState.inheritFromId : false;

  return {
    override,
    defaultState,
    customState,
    isSaving: false,
    isResetting: false,
    isLoadingJiraIssueTypes: false,
    loadingJiraIssueTypesErrorMessage: '',
    jiraIssueTypes: [],
  };
};
