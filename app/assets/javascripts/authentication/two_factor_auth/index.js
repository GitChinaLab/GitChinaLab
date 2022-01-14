import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { updateHistory, removeParams } from '~/lib/utils/url_utility';
import ManageTwoFactorForm from './components/manage_two_factor_form.vue';
import RecoveryCodes from './components/recovery_codes.vue';
import { SUCCESS_QUERY_PARAM } from './constants';

export const initManageTwoFactorForm = () => {
  const el = document.querySelector('.js-manage-two-factor-form');

  if (!el) {
    return false;
  }

  const {
    webauthnEnabled = false,
    currentPasswordRequired,
    profileTwoFactorAuthPath = '',
    profileTwoFactorAuthMethod = '',
    codesProfileTwoFactorAuthPath = '',
    codesProfileTwoFactorAuthMethod = '',
  } = el.dataset;

  const isCurrentPasswordRequired = parseBoolean(currentPasswordRequired);

  return new Vue({
    el,
    provide: {
      webauthnEnabled,
      isCurrentPasswordRequired,
      profileTwoFactorAuthPath,
      profileTwoFactorAuthMethod,
      codesProfileTwoFactorAuthPath,
      codesProfileTwoFactorAuthMethod,
    },
    render(createElement) {
      return createElement(ManageTwoFactorForm);
    },
  });
};

export const initRecoveryCodes = () => {
  const el = document.querySelector('.js-2fa-recovery-codes');

  if (!el) {
    return false;
  }

  const { codes = '[]', profileAccountPath = '' } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(RecoveryCodes, {
        props: {
          codes: JSON.parse(codes),
          profileAccountPath,
        },
      });
    },
  });
};

export const initClose2faSuccessMessage = () => {
  const closeButton = document.querySelector('.js-close-2fa-enabled-success-alert');

  if (!closeButton) {
    return;
  }

  closeButton.addEventListener(
    'click',
    () => {
      updateHistory({
        url: removeParams([SUCCESS_QUERY_PARAM]),
        title: document.title,
        replace: true,
      });
    },
    { once: true },
  );
};
