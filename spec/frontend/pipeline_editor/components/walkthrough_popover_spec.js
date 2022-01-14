import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import WalkthroughPopover from '~/pipeline_editor/components/walkthrough_popover.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.config.ignoredElements = ['gl-emoji'];

describe('WalkthroughPopover component', () => {
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    return extendedWrapper(mountFn(WalkthroughPopover));
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('CTA button clicked', () => {
    beforeEach(async () => {
      wrapper = createComponent(mount);
      await wrapper.findByTestId('ctaBtn').trigger('click');
    });

    it('emits "walkthrough-popover-cta-clicked" event', async () => {
      expect(wrapper.emitted()['walkthrough-popover-cta-clicked']).toBeTruthy();
    });
  });
});
