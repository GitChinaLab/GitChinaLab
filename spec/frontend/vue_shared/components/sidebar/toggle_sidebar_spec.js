import { GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import ToggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';

describe('ToggleSidebar', () => {
  let wrapper;

  const defaultProps = {
    collapsed: true,
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(ToggleSidebar, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlButton = () => wrapper.findComponent(GlButton);

  it('should render the "chevron-double-lg-left" icon when collapsed', () => {
    createComponent();

    expect(findGlButton().props('icon')).toBe('chevron-double-lg-left');
  });

  it('should render the "chevron-double-lg-right" icon when expanded', async () => {
    createComponent({ props: { collapsed: false } });

    expect(findGlButton().props('icon')).toBe('chevron-double-lg-right');
  });

  it('should emit toggle event when button clicked', async () => {
    createComponent({ mountFn: mount });

    findGlButton().trigger('click');
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('toggle')[0]).toBeDefined();
  });
});
