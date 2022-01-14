import { GlDropdown } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import createEventHub from '~/helpers/event_hub_factory';

import axios from '~/lib/utils/axios_utils';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import { DISCUSSION_FILTERS_DEFAULT_VALUE, DISCUSSION_FILTER_TYPES } from '~/notes/constants';
import notesModule from '~/notes/stores/modules';

import { discussionFiltersMock, discussionMock } from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

const DISCUSSION_PATH = `${TEST_HOST}/example`;

describe('DiscussionFilter component', () => {
  let wrapper;
  let store;
  let eventHub;
  let mock;

  const filterDiscussion = jest.fn();

  const findFilter = (filterType) =>
    wrapper.find(`.dropdown-item[data-filter-type="${filterType}"]`);

  const mountComponent = () => {
    const discussions = [
      {
        ...discussionMock,
        id: discussionMock.id,
        notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
      },
    ];

    const defaultStore = { ...notesModule() };

    store = new Vuex.Store({
      ...defaultStore,
      actions: {
        ...defaultStore.actions,
        filterDiscussion,
      },
    });

    store.state.notesData.discussionsPath = DISCUSSION_PATH;

    store.state.discussions = discussions;

    return mount(DiscussionFilter, {
      store,
      propsData: {
        filters: discussionFiltersMock,
        selectedValue: DISCUSSION_FILTERS_DEFAULT_VALUE,
      },
      localVue,
    });
  };

  beforeEach(() => {
    mock = new AxiosMockAdapter(axios);

    // We are mocking the discussions retrieval,
    // as it doesn't matter for our tests here
    mock.onGet(DISCUSSION_PATH).reply(200, '');
    window.mrTabs = undefined;
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.vm.$destroy();
    mock.restore();
  });

  it('renders the all filters', () => {
    expect(wrapper.findAll('.discussion-filter-container .dropdown-item').length).toBe(
      discussionFiltersMock.length,
    );
  });

  it('renders the default selected item', () => {
    expect(wrapper.find('#discussion-filter-dropdown .dropdown-item').text().trim()).toBe(
      discussionFiltersMock[0].title,
    );
  });

  it('disables the dropdown when discussions are loading', () => {
    store.state.isLoading = true;

    expect(wrapper.findComponent(GlDropdown).props('disabled')).toBe(true);
  });

  it('updates to the selected item', () => {
    const filterItem = findFilter(DISCUSSION_FILTER_TYPES.ALL);

    filterItem.trigger('click');

    expect(wrapper.vm.currentFilter.title).toBe(filterItem.text().trim());
  });

  it('only updates when selected filter changes', () => {
    findFilter(DISCUSSION_FILTER_TYPES.ALL).trigger('click');

    expect(filterDiscussion).not.toHaveBeenCalled();
  });

  it('disables timeline view if it was enabled', () => {
    store.state.isTimelineEnabled = true;

    findFilter(DISCUSSION_FILTER_TYPES.HISTORY).trigger('click');

    expect(wrapper.vm.$store.state.isTimelineEnabled).toBe(false);
  });

  it('disables commenting when "Show history only" filter is applied', () => {
    findFilter(DISCUSSION_FILTER_TYPES.HISTORY).trigger('click');

    expect(wrapper.vm.$store.state.commentsDisabled).toBe(true);
  });

  it('enables commenting when "Show history only" filter is not applied', () => {
    findFilter(DISCUSSION_FILTER_TYPES.ALL).trigger('click');

    expect(wrapper.vm.$store.state.commentsDisabled).toBe(false);
  });

  it('renders a dropdown divider for the default filter', () => {
    const defaultFilter = wrapper.findAll(
      `.discussion-filter-container .dropdown-item-wrapper > *`,
    );

    expect(defaultFilter.at(1).classes('gl-new-dropdown-divider')).toBe(true);
  });

  describe('Merge request tabs', () => {
    eventHub = createEventHub();

    beforeEach(() => {
      window.mrTabs = {
        eventHub,
        currentTab: 'show',
      };

      wrapper = mountComponent();
    });

    afterEach(() => {
      window.mrTabs = undefined;
    });

    it('only renders when discussion tab is active', (done) => {
      eventHub.$emit('MergeRequestTabChange', 'commit');

      wrapper.vm.$nextTick(() => {
        expect(wrapper.html()).toBe('');
        done();
      });
    });
  });

  describe('URL with Links to notes', () => {
    afterEach(() => {
      window.location.hash = '';
    });

    it('updates the filter when the URL links to a note', (done) => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      wrapper.vm.currentValue = discussionFiltersMock[2].value;
      wrapper.vm.handleLocationHash();

      wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.currentValue).toBe(DISCUSSION_FILTERS_DEFAULT_VALUE);
        done();
      });
    });

    it('does not update the filter when the current filter is "Show all activity"', (done) => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      wrapper.vm.handleLocationHash();

      wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.currentValue).toBe(DISCUSSION_FILTERS_DEFAULT_VALUE);
        done();
      });
    });

    it('only updates filter when the URL links to a note', (done) => {
      window.location.hash = `testing123`;
      wrapper.vm.handleLocationHash();

      wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.currentValue).toBe(DISCUSSION_FILTERS_DEFAULT_VALUE);
        done();
      });
    });

    it('fetches discussions when there is a hash', (done) => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      wrapper.vm.currentValue = discussionFiltersMock[2].value;
      jest.spyOn(wrapper.vm, 'selectFilter').mockImplementation(() => {});
      wrapper.vm.handleLocationHash();

      wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.selectFilter).toHaveBeenCalled();
        done();
      });
    });

    it('does not fetch discussions when there is no hash', (done) => {
      window.location.hash = '';
      jest.spyOn(wrapper.vm, 'selectFilter').mockImplementation(() => {});
      wrapper.vm.handleLocationHash();

      wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.selectFilter).not.toHaveBeenCalled();
        done();
      });
    });
  });
});
