/* eslint-disable no-param-reassign, consistent-return */

import AccessorUtilities from './lib/utils/accessor';

export default class Autosave {
  constructor(field, key, fallbackKey, lockVersion) {
    this.field = field;

    this.isLocalStorageAvailable = AccessorUtilities.canUseLocalStorage();
    if (key.join != null) {
      key = key.join('/');
    }
    this.key = `autosave/${key}`;
    this.fallbackKey = fallbackKey;
    this.lockVersionKey = `${this.key}/lockVersion`;
    this.lockVersion = lockVersion;
    this.field.data('autosave', this);
    this.restore();
    this.field.on('input', () => this.save());
  }

  restore() {
    if (!this.isLocalStorageAvailable) return;
    if (!this.field.length) return;

    const text = window.localStorage.getItem(this.key);
    const fallbackText = window.localStorage.getItem(this.fallbackKey);

    if (text) {
      this.field.val(text);
    } else if (fallbackText) {
      this.field.val(fallbackText);
    }

    this.field.trigger('input');
    // v-model does not update with jQuery trigger
    // https://github.com/vuejs/vue/issues/2804#issuecomment-216968137
    const event = new Event('change', { bubbles: true, cancelable: false });
    const field = this.field.get(0);
    if (field) {
      field.dispatchEvent(event);
    }
  }

  getSavedLockVersion() {
    if (!this.isLocalStorageAvailable) return;
    return window.localStorage.getItem(this.lockVersionKey);
  }

  save() {
    if (!this.field.length) return;

    const text = this.field.val();

    if (this.isLocalStorageAvailable && text) {
      if (this.fallbackKey) {
        window.localStorage.setItem(this.fallbackKey, text);
      }
      if (this.lockVersion !== undefined) {
        window.localStorage.setItem(this.lockVersionKey, this.lockVersion);
      }
      return window.localStorage.setItem(this.key, text);
    }

    return this.reset();
  }

  reset() {
    if (!this.isLocalStorageAvailable) return;

    window.localStorage.removeItem(this.lockVersionKey);
    window.localStorage.removeItem(this.fallbackKey);
    return window.localStorage.removeItem(this.key);
  }

  dispose() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.field.off('input');
  }
}
