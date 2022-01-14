import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import resolveDiscussionButton from '~/notes/components/discussion_resolve_button.vue';

const buttonTitle = 'Resolve discussion';

describe('resolveDiscussionButton', () => {
  let wrapper;

  const factory = (options) => {
    wrapper = shallowMount(resolveDiscussionButton, {
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        isResolving: false,
        buttonTitle,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should emit a onClick event on button click', () => {
    const button = wrapper.find(GlButton);

    button.vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted()).toEqual({
        onClick: [[]],
      });
    });
  });

  it('should contain the provided button title', () => {
    const button = wrapper.find(GlButton);

    expect(button.text()).toContain(buttonTitle);
  });

  it('should show a loading spinner while resolving', () => {
    factory({
      propsData: {
        isResolving: true,
        buttonTitle,
      },
    });

    const button = wrapper.find(GlButton);

    expect(button.props('loading')).toEqual(true);
  });

  it('should only show a loading spinner while resolving', () => {
    factory({
      propsData: {
        isResolving: false,
        buttonTitle,
      },
    });

    const button = wrapper.find(GlButton);

    wrapper.vm.$nextTick(() => {
      expect(button.props('loading')).toEqual(false);
    });
  });
});
