import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import ConfirmModal from '~/lib/utils/confirm_via_gl_modal/confirm_modal.vue';

describe('Confirm Modal', () => {
  let wrapper;
  let modal;

  const createComponent = ({ primaryText, primaryVariant } = {}) => {
    wrapper = mount(ConfirmModal, {
      propsData: {
        primaryText,
        primaryVariant,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlModal = () => wrapper.findComponent(GlModal);

  describe('Modal events', () => {
    beforeEach(() => {
      createComponent();
      modal = findGlModal();
    });

    it('should emit `confirmed` event on `primary` modal event', () => {
      findGlModal().vm.$emit('primary');
      expect(wrapper.emitted('confirmed')).toBeTruthy();
    });

    it('should emit closed` event on `hidden` modal event', () => {
      modal.vm.$emit('hidden');
      expect(wrapper.emitted('closed')).toBeTruthy();
    });
  });

  describe('Custom properties', () => {
    it('should pass correct custom primary text & button variant to the modal when provided', () => {
      const primaryText = "Let's do it!";
      const primaryVariant = 'danger';

      createComponent({ primaryText, primaryVariant });
      const customProps = findGlModal().props('actionPrimary');
      expect(customProps.text).toBe(primaryText);
      expect(customProps.attributes.variant).toBe(primaryVariant);
    });

    it('should pass default primary text & button variant to the modal if no custom values provided', () => {
      createComponent();
      const customProps = findGlModal().props('actionPrimary');
      expect(customProps.text).toBe('OK');
      expect(customProps.attributes.variant).toBe('confirm');
    });
  });
});
