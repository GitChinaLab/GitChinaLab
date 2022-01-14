const agent = {
  id: 'agent-id',
  name: 'agent-name',
  webPath: 'agent-webPath',
};
const token = {
  id: 'token-id',
  lastUsedAt: null,
};
const tokens = {
  nodes: [token],
};
const pageInfo = {
  endCursor: '',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: '',
};
const count = 1;

export const createAgentResponse = {
  data: {
    createClusterAgent: {
      clusterAgent: {
        ...agent,
        tokens,
      },
      errors: [],
    },
  },
};

export const createAgentErrorResponse = {
  data: {
    createClusterAgent: {
      clusterAgent: {
        ...agent,
        tokens,
      },
      errors: ['could not create agent'],
    },
  },
};

export const createAgentTokenResponse = {
  data: {
    clusterAgentTokenCreate: {
      token,
      secret: 'mock-agent-token',
      errors: [],
    },
  },
};

export const createAgentTokenErrorResponse = {
  data: {
    clusterAgentTokenCreate: {
      token,
      secret: 'mock-agent-token',
      errors: ['could not create agent token'],
    },
  },
};

export const getAgentResponse = {
  data: {
    project: {
      id: 'project-1',
      clusterAgents: { nodes: [{ ...agent, tokens }], pageInfo, count },
      repository: {
        tree: {
          trees: { nodes: [{ ...agent, path: null }], pageInfo },
        },
      },
    },
  },
};
