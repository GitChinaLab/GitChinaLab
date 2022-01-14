import Vue from 'vue';
import VueApollo from 'vue-apollo';
import loadAwardsHandler from '~/awards_handler';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { initPipelineCountListener } from '~/commit/pipelines/utils';
import { initIssuableSidebar } from '~/issuable';
import StatusBox from '~/issuable/components/status_box.vue';
import createDefaultClient from '~/lib/graphql';
import initSourcegraph from '~/sourcegraph';
import ZenMode from '~/zen_mode';
import getStateQuery from './queries/get_state.query.graphql';

export default function initMergeRequestShow() {
  const awardEmojiEl = document.getElementById('js-vue-awards-block');

  new ZenMode(); // eslint-disable-line no-new
  initPipelineCountListener(document.querySelector('#commit-pipeline-table-view'));
  new ShortcutsIssuable(true); // eslint-disable-line no-new
  initSourcegraph();
  initIssuableSidebar();
  if (awardEmojiEl) {
    import('~/emoji/awards_app')
      .then((m) => m.default(awardEmojiEl))
      .catch(() => {});
  } else {
    loadAwardsHandler();
  }

  const el = document.querySelector('.js-mr-status-box');
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });
  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      query: getStateQuery,
      projectPath: el.dataset.projectPath,
      iid: el.dataset.iid,
    },
    render(h) {
      return h(StatusBox, {
        props: {
          initialState: el.dataset.state,
        },
      });
    },
  });
}
