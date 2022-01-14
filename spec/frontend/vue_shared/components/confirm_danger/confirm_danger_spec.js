import { GlButton } from '@gitlab/ui';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import ConfirmDangerModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';
import { CONFIRM_DANGER_MODAL_ID } from '~/vue_shared/components/confirm_danger/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Confirm Danger Modal', () => {
  let wrapper;

  const phrase = 'En Taro Adun';
  const buttonText = 'Click me!';
  const buttonClass = 'gl-w-full';
  const modalId = CONFIRM_DANGER_MODAL_ID;

  const findBtn = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(ConfirmDangerModal);
  const findModalProps = () => findModal().props();

  const createComponent = (props = {}) =>
    shallowMountExtended(ConfirmDanger, {
      propsData: {
        buttonText,
        buttonClass,
        phrase,
        ...props,
      },
    });

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the button', () => {
    expect(wrapper.html()).toContain(buttonText);
  });

  it('sets the modal properties', () => {
    expect(findModalProps()).toMatchObject({
      modalId,
      phrase,
    });
  });

  it('will disable the button if `disabled=true`', () => {
    expect(findBtn().attributes('disabled')).toBeUndefined();

    wrapper = createComponent({ disabled: true });

    expect(findBtn().attributes('disabled')).toBe('true');
  });

  it('passes `buttonClass` prop to button', () => {
    expect(findBtn().classes()).toContain(buttonClass);
  });

  it('will emit `confirm` when the modal confirms', () => {
    expect(wrapper.emitted('confirm')).toBeUndefined();

    findModal().vm.$emit('confirm');

    expect(wrapper.emitted('confirm')).not.toBeUndefined();
  });
});
