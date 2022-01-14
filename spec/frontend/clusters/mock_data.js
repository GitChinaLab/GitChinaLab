const user = {
  id: 1,
  name: 'Administrator',
  username: 'root',
  webUrl: 'http://172.31.0.1:3000/root',
};

const agentToken = {
  id: 1,
  name: 'cluster-agent',
};

export const defaultActivityEvent = {
  kind: 'unknown_agent',
  level: 'info',
  recordedAt: '2021-11-22T19:26:56Z',
  agentToken,
  user,
};

export const mockAgentActivityEvents = [
  {
    kind: 'token_created',
    level: 'info',
    recordedAt: '2021-12-03T01:06:56Z',
    agentToken,
    user,
  },

  {
    kind: 'token_revoked',
    level: 'info',
    recordedAt: '2021-12-03T00:26:56Z',
    agentToken,
    user,
  },

  {
    kind: 'agent_connected',
    level: 'info',
    recordedAt: '2021-12-02T19:26:56Z',
    agentToken,
    user,
  },

  {
    kind: 'agent_disconnected',
    level: 'info',
    recordedAt: '2021-12-02T19:26:56Z',
    agentToken,
    user,
  },

  {
    kind: 'agent_connected',
    level: 'info',
    recordedAt: '2021-11-22T19:26:56Z',
    agentToken,
    user,
  },

  {
    kind: 'unknown_agent',
    level: 'info',
    recordedAt: '2021-11-22T19:26:56Z',
    agentToken,
    user,
  },
];

export const mockResponse = {
  data: {
    project: {
      id: 'project-1',
      clusterAgent: {
        id: 'cluster-agent',
        activityEvents: {
          nodes: mockAgentActivityEvents,
        },
      },
    },
  },
};

export const mockEmptyResponse = {
  data: {
    project: {
      id: 'project-1',
      clusterAgent: {
        id: 'cluster-agent',
        activityEvents: {
          nodes: [],
        },
      },
    },
  },
};

export const mockAgentHistoryActivityItems = [
  {
    kind: 'token_created',
    level: 'info',
    recordedAt: '2021-12-03T01:06:56Z',
    agentToken,
    user,
    eventTypeIcon: 'token',
    title: 'cluster-agent created',
    body: 'Token created by Administrator',
  },

  {
    kind: 'token_revoked',
    level: 'info',
    recordedAt: '2021-12-03T00:26:56Z',
    agentToken,
    user,
    eventTypeIcon: 'token',
    title: 'cluster-agent revoked',
    body: 'Token revoked by Administrator',
  },

  {
    kind: 'agent_connected',
    level: 'info',
    recordedAt: '2021-12-02T19:26:56Z',
    agentToken,
    user,
    eventTypeIcon: 'connected',
    title: 'Connected',
    body: 'Agent Connected',
  },

  {
    kind: 'agent_disconnected',
    level: 'info',
    recordedAt: '2021-12-02T19:26:56Z',
    agentToken,
    user,
    eventTypeIcon: 'connected',
    title: 'Not connected',
    body: 'Agent Not connected',
  },

  {
    kind: 'agent_connected',
    level: 'info',
    recordedAt: '2021-11-22T19:26:56Z',
    agentToken,
    user,
    eventTypeIcon: 'connected',
    title: 'Connected',
    body: 'Agent Connected',
  },

  {
    kind: 'unknown_agent',
    level: 'info',
    recordedAt: '2021-11-22T19:26:56Z',
    agentToken,
    user,
    eventTypeIcon: 'token',
    title: 'unknown_agent',
    body: 'Event occurred',
  },
];
