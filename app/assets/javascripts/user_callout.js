import $ from 'jquery';
import Cookies from 'js-cookie';

export default class UserCallout {
  constructor(options = {}) {
    this.options = options;

    const className = this.options.className || 'user-callout';

    this.userCalloutBody = $(`.${className}`);
    this.cookieName = this.userCalloutBody.data('uid');
    this.isCalloutDismissed = Cookies.get(this.cookieName);
    this.init();
  }

  init() {
    if (!this.isCalloutDismissed || this.isCalloutDismissed === 'false') {
      this.userCalloutBody.find('.js-close-callout').on('click', (e) => this.dismissCallout(e));
    }
  }

  dismissCallout(e) {
    const $currentTarget = $(e.currentTarget);
    const cookieOptions = {};

    if (!$currentTarget.hasClass('js-close-session')) {
      cookieOptions.expires = 365;
    }
    if (this.options.setCalloutPerProject) {
      cookieOptions.path = this.userCalloutBody.data('projectPath');
    }

    Cookies.set(this.cookieName, 'true', cookieOptions);

    if ($currentTarget.hasClass('close') || $currentTarget.hasClass('js-close')) {
      this.userCalloutBody.remove();
    }
  }
}
