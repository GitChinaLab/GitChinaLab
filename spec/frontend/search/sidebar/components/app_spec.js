import { GlButton, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchSidebar, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSidebarForm = () => wrapper.find('form');
  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findConfidentialityFilter = () => wrapper.findComponent(ConfidentialityFilter);
  const findApplyButton = () => wrapper.findComponent(GlButton);
  const findResetLinkButton = () => wrapper.findComponent(GlLink);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders StatusFilter always', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter always', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });

    it('renders ApplyButton always', () => {
      expect(findApplyButton().exists()).toBe(true);
    });
  });

  describe('ApplyButton', () => {
    describe('when sidebarDirty is false', () => {
      beforeEach(() => {
        createComponent({ sidebarDirty: false });
      });

      it('disables the button', () => {
        expect(findApplyButton().attributes('disabled')).toBe('true');
      });
    });

    describe('when sidebarDirty is true', () => {
      beforeEach(() => {
        createComponent({ sidebarDirty: true });
      });

      it('enables the button', () => {
        expect(findApplyButton().attributes('disabled')).toBe(undefined);
      });
    });
  });

  describe('ResetLinkButton', () => {
    describe('with no filter selected', () => {
      beforeEach(() => {
        createComponent({ urlQuery: {} });
      });

      it('does not render', () => {
        expect(findResetLinkButton().exists()).toBe(false);
      });
    });

    describe('with filter selected', () => {
      beforeEach(() => {
        createComponent({ urlQuery: MOCK_QUERY });
      });

      it('does render', () => {
        expect(findResetLinkButton().exists()).toBe(true);
      });
    });

    describe('with filter selected and user updated query back to default', () => {
      beforeEach(() => {
        createComponent({ urlQuery: MOCK_QUERY, query: {} });
      });

      it('does render', () => {
        expect(findResetLinkButton().exists()).toBe(true);
      });
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('clicking ApplyButton calls applyQuery', () => {
      findSidebarForm().trigger('submit');

      expect(actionSpies.applyQuery).toHaveBeenCalled();
    });

    it('clicking ResetLinkButton calls resetQuery', () => {
      findResetLinkButton().vm.$emit('click');

      expect(actionSpies.resetQuery).toHaveBeenCalled();
    });
  });
});
