import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PackagesApp from '~/packages_and_registries/infrastructure_registry/details/components/app.vue';
import createStore from '~/packages_and_registries/infrastructure_registry/details/store';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export default () => {
  const el = document.querySelector('#js-vue-packages-detail');
  const { package: packageJson, canDelete: canDeleteStr, ...rest } = el.dataset;
  const packageEntity = JSON.parse(packageJson);
  const canDelete = parseBoolean(canDeleteStr);

  const store = createStore({
    packageEntity,
    packageFiles: packageEntity.package_files,
    canDelete,
    ...rest,
  });

  return new Vue({
    el,
    store,
    provide: {
      titleComponent: 'TerraformTitle',
    },
    render(createElement) {
      return createElement(PackagesApp);
    },
  });
};
