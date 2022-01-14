import produce from 'immer';
import { getAgentConfigPath } from '../clusters_util';

export const hasErrors = ({ errors = [] }) => errors?.length;

export function addAgentToStore(store, createClusterAgent, query, variables) {
  if (!hasErrors(createClusterAgent)) {
    const { clusterAgent } = createClusterAgent;
    const sourceData = store.readQuery({
      query,
      variables,
    });

    const data = produce(sourceData, (draftData) => {
      const configuration = {
        id: clusterAgent.id,
        name: clusterAgent.name,
        path: getAgentConfigPath(clusterAgent.name),
        webPath: clusterAgent.webPath,
        __typename: 'TreeEntry',
      };

      draftData.project.clusterAgents.nodes.push(clusterAgent);
      draftData.project.clusterAgents.count += 1;
      draftData.project.repository.tree.trees.nodes.push(configuration);
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}

export function addAgentConfigToStore(
  store,
  clusterAgentTokenCreate,
  clusterAgent,
  query,
  variables,
) {
  if (!hasErrors(clusterAgentTokenCreate)) {
    const sourceData = store.readQuery({
      query,
      variables,
    });

    const data = produce(sourceData, (draftData) => {
      const configuration = {
        agentName: clusterAgent.name,
        __typename: 'AgentConfiguration',
      };

      draftData.project.clusterAgents.nodes.push(clusterAgent);
      draftData.project.agentConfigurations.nodes.push(configuration);
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}
