import Vue from 'vue';
import { initStoreFromElement, initPropsFromElement } from '~/import_entities/import_projects';
import BitbucketStatusTable from '~/import_entities/import_projects/components/bitbucket_status_table.vue';

function importBitBucket() {
  const mountElement = document.getElementById('import-projects-mount-element');
  if (!mountElement) return undefined;

  const store = initStoreFromElement(mountElement);
  const attrs = initPropsFromElement(mountElement);

  return new Vue({
    el: mountElement,
    store,
    render(createElement) {
      return createElement(BitbucketStatusTable, { attrs });
    },
  });
}

importBitBucket();
