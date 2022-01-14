import { GlButton, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Actions from '~/vue_merge_request_widget/components/extensions/actions.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = shallowMount(Actions, {
    propsData: { ...propsData, widget: 'test' },
  });
}

describe('MR widget extension actions', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  describe('tertiaryButtons', () => {
    it('renders buttons', () => {
      factory({
        tertiaryButtons: [{ text: 'hello world', href: 'https://gitlab.com', target: '_blank' }],
      });

      expect(wrapper.findAllComponents(GlButton)).toHaveLength(1);
    });

    it('calls action click handler', async () => {
      const onClick = jest.fn();

      factory({
        tertiaryButtons: [{ text: 'hello world', onClick }],
      });

      await wrapper.findComponent(GlButton).vm.$emit('click');

      expect(onClick).toHaveBeenCalled();
    });

    it('renders tertiary actions in dropdown', () => {
      factory({
        tertiaryButtons: [{ text: 'hello world', href: 'https://gitlab.com', target: '_blank' }],
      });

      expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(1);
    });
  });
});
