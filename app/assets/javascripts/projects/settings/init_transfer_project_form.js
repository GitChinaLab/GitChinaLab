import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import TransferProjectForm from './components/transfer_project_form.vue';

const prepareNamespaces = (rawNamespaces = '') => {
  const data = JSON.parse(rawNamespaces);
  return {
    group: data?.group.map(convertObjectPropsToCamelCase),
    user: data?.user.map(convertObjectPropsToCamelCase),
  };
};

export default () => {
  const el = document.querySelector('.js-transfer-project-form');
  if (!el) {
    return false;
  }

  const {
    targetFormId = null,
    targetHiddenInputId = null,
    buttonText: confirmButtonText = '',
    phrase: confirmationPhrase = '',
    confirmDangerMessage = '',
    namespaces = '',
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      confirmDangerMessage,
    },
    render(createElement) {
      return createElement(TransferProjectForm, {
        props: {
          confirmButtonText,
          confirmationPhrase,
          namespaces: prepareNamespaces(namespaces),
        },
        on: {
          selectNamespace: (id) => {
            if (targetHiddenInputId && document.getElementById(targetHiddenInputId)) {
              document.getElementById(targetHiddenInputId).value = id;
            }
          },
          confirm: () => {
            if (targetFormId) document.getElementById(targetFormId)?.submit();
          },
        },
      });
    },
  });
};
