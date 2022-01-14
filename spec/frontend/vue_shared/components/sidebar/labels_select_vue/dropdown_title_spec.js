import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import DropdownTitle from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_title.vue';

import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

import { mockConfig } from './mock_data';

Vue.use(Vuex);

const createComponent = (initialState = mockConfig) => {
  const store = new Vuex.Store(labelsSelectModule());

  store.dispatch('setInitialState', initialState);

  return shallowMount(DropdownTitle, {
    store,
    propsData: {
      labelsSelectInProgress: false,
    },
  });
};

describe('DropdownTitle', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders component container element with string "Labels"', () => {
      expect(wrapper.text()).toContain('Labels');
    });

    it('renders edit link', () => {
      const editBtnEl = wrapper.find(GlButton);

      expect(editBtnEl.exists()).toBe(true);
      expect(editBtnEl.text()).toBe('Edit');
    });

    it('renders loading icon element when `labelsSelectInProgress` prop is true', () => {
      wrapper.setProps({
        labelsSelectInProgress: true,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
      });
    });
  });
});
