import { mount } from '@vue/test-utils';
import TotalTimeComponent from '~/cycle_analytics/components/total_time_component.vue';

describe('TotalTimeComponent', () => {
  let wrapper = null;

  const createComponent = (propsData) => {
    return mount(TotalTimeComponent, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with a valid time object', () => {
    it.each`
      time
      ${{ seconds: 35 }}
      ${{ mins: 47, seconds: 3 }}
      ${{ days: 3, mins: 47, seconds: 3 }}
      ${{ hours: 23, mins: 10 }}
      ${{ hours: 7, mins: 20, seconds: 10 }}
    `('with $time', ({ time }) => {
      wrapper = createComponent({
        time,
      });

      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('with a blank object', () => {
    beforeEach(() => {
      wrapper = createComponent({
        time: {},
      });
    });

    it('should render --', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });
});
