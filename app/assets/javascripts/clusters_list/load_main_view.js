import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ClustersMainView from './components/clusters_main_view.vue';
import { createStore } from './store';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('.js-clusters-main-view');

  if (!el) {
    return null;
  }

  const defaultClient = createDefaultClient();

  const {
    emptyStateImage,
    defaultBranchName,
    projectPath,
    kasAddress,
    newClusterPath,
    addClusterPath,
    emptyStateHelpText,
    clustersEmptyStateImage,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider: new VueApollo({ defaultClient }),
    provide: {
      emptyStateImage,
      projectPath,
      kasAddress,
      newClusterPath,
      addClusterPath,
      emptyStateHelpText,
      clustersEmptyStateImage,
    },
    store: createStore(el.dataset),
    render(createElement) {
      return createElement(ClustersMainView, {
        props: {
          defaultBranchName,
        },
      });
    },
  });
};
