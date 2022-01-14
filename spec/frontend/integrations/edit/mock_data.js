export const mockIntegrationProps = {
  id: 25,
  initialActivated: true,
  showActive: true,
  editable: true,
  triggerFieldsProps: {
    initialTriggerCommit: false,
    initialTriggerMergeRequest: false,
    initialEnableComments: false,
  },
  jiraIssuesProps: {},
  triggerEvents: [],
  fields: [],
  type: '',
  inheritFromId: 25,
};

export const mockJiraIssueTypes = [
  { id: '1', name: 'issue', description: 'issue' },
  { id: '2', name: 'bug', description: 'bug' },
  { id: '3', name: 'epic', description: 'epic' },
];
