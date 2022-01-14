import { GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import * as commonUtils from '~/lib/utils/common_utils';
import MembersApp from '~/members/components/app.vue';
import FilterSortContainer from '~/members/components/filter_sort/filter_sort_container.vue';
import MembersTable from '~/members/components/table/members_table.vue';
import { MEMBER_TYPES, TAB_QUERY_PARAM_VALUES } from '~/members/constants';
import { RECEIVE_MEMBER_ROLE_ERROR, HIDE_ERROR } from '~/members/store/mutation_types';
import mutations from '~/members/store/mutations';

describe('MembersApp', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;
  let store;

  const createComponent = (state = {}, options = {}) => {
    store = new Vuex.Store({
      modules: {
        [MEMBER_TYPES.group]: {
          namespaced: true,
          state: {
            showError: true,
            errorMessage: 'Something went wrong, please try again.',
            ...state,
          },
          mutations,
        },
      },
    });

    wrapper = shallowMount(MembersApp, {
      localVue,
      propsData: {
        namespace: MEMBER_TYPES.group,
        tabQueryParamValue: TAB_QUERY_PARAM_VALUES.group,
      },
      store,
      ...options,
    });
  };

  const findAlert = () => wrapper.find(GlAlert);
  const findFilterSortContainer = () => wrapper.find(FilterSortContainer);

  beforeEach(() => {
    commonUtils.scrollToElement = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    store = null;
  });

  describe('when `showError` is changed to `true`', () => {
    it('renders and scrolls to error alert', async () => {
      createComponent({ showError: false, errorMessage: '' });

      store.commit(`${MEMBER_TYPES.group}/${RECEIVE_MEMBER_ROLE_ERROR}`, {
        error: new Error('Network Error'),
      });

      await nextTick();

      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(
        "An error occurred while updating the member's role, please try again.",
      );
      expect(commonUtils.scrollToElement).toHaveBeenCalledWith(alert.element);
    });
  });

  describe('when `showError` is changed to `false`', () => {
    it('does not render and scroll to error alert', async () => {
      createComponent();

      store.commit(`${MEMBER_TYPES.group}/${HIDE_ERROR}`);

      await nextTick();

      expect(findAlert().exists()).toBe(false);
      expect(commonUtils.scrollToElement).not.toHaveBeenCalled();
    });
  });

  describe('when alert is dismissed', () => {
    it('hides alert', async () => {
      createComponent();

      findAlert().vm.$emit('dismiss');

      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });

  it('renders `FilterSortContainer`', () => {
    createComponent();

    expect(findFilterSortContainer().exists()).toBe(true);
  });

  it('renders `MembersTable` component and passes `tabQueryParamValue` prop', () => {
    createComponent();

    const membersTableComponent = wrapper.findComponent(MembersTable);

    expect(membersTableComponent.exists()).toBe(true);
    expect(membersTableComponent.props('tabQueryParamValue')).toBe(TAB_QUERY_PARAM_VALUES.group);
  });
});
