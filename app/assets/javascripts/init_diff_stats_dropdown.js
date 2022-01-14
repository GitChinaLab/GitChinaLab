import Vue from 'vue';
import DiffStatsDropdown from '~/vue_shared/components/diff_stats_dropdown.vue';
import { stickyMonitor } from './lib/utils/sticky';

export const initDiffStatsDropdown = (stickyTop) => {
  if (stickyTop) {
    stickyMonitor(document.querySelector('.js-diff-files-changed'), stickyTop);
  }

  const el = document.querySelector('.js-diff-stats-dropdown');

  if (!el) {
    return false;
  }

  const { changed, added, deleted, files } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(DiffStatsDropdown, {
        props: {
          changed: parseInt(changed, 10),
          added: parseInt(added, 10),
          deleted: parseInt(deleted, 10),
          files: JSON.parse(files),
        },
      }),
  });
};
