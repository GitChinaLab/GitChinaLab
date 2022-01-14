import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';

class Landing {
  constructor(landingElement, dismissButton, cookieName) {
    this.landingElement = landingElement;
    this.cookieName = cookieName;
    this.dismissButton = dismissButton;
    this.eventWrapper = {};
  }

  toggle() {
    const isDismissed = this.isDismissed();

    this.landingElement.classList.toggle('hidden', isDismissed);
    if (!isDismissed) this.addEvents();
  }

  addEvents() {
    this.eventWrapper.dismissLanding = this.dismissLanding.bind(this);
    this.dismissButton.addEventListener('click', this.eventWrapper.dismissLanding);
  }

  removeEvents() {
    this.dismissButton.removeEventListener('click', this.eventWrapper.dismissLanding);
  }

  dismissLanding() {
    this.landingElement.classList.add('hidden');
    Cookies.set(this.cookieName, 'true', { expires: 365 });
  }

  isDismissed() {
    return parseBoolean(Cookies.get(this.cookieName));
  }
}

export default Landing;
