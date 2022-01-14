import { shallowMount } from '@vue/test-utils';

import LabelItem from '~/vue_shared/components/sidebar/labels_select_widget/label_item.vue';
import { mockRegularLabel } from './mock_data';

const mockLabel = { ...mockRegularLabel, set: true };

const createComponent = ({ label = mockLabel } = {}) =>
  shallowMount(LabelItem, {
    propsData: {
      label,
    },
  });

describe('LabelItem', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders label color element', () => {
      const colorEl = wrapper.find('[data-testid="label-color-box"]');

      expect(colorEl.exists()).toBe(true);
      expect(colorEl.attributes('style')).toBe('background-color: rgb(186, 218, 85);');
    });

    it('renders label title', () => {
      expect(wrapper.text()).toContain(mockLabel.title);
    });
  });
});
