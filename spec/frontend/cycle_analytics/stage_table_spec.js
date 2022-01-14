import { GlEmptyState, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import StageTable from '~/cycle_analytics/components/stage_table.vue';
import { PAGINATION_SORT_FIELD_DURATION } from '~/cycle_analytics/constants';
import { issueEvents, issueStage, reviewStage, reviewEvents } from './mock_data';

let wrapper = null;
let trackingSpy = null;

const noDataSvgPath = 'path/to/no/data';
const emptyStateTitle = 'Too much data';
const notEnoughDataError = "We don't have enough data to show this stage.";
const issueEventItems = issueEvents.events;
const reviewEventItems = reviewEvents.events;
const [firstIssueEvent] = issueEventItems;
const [firstReviewEvent] = reviewEventItems;
const pagination = { page: 1, hasNextPage: true };

const findStageEvents = () => wrapper.findAllByTestId('vsa-stage-event');
const findPagination = () => wrapper.findByTestId('vsa-stage-pagination');
const findTable = () => wrapper.findComponent(GlTable);
const findTableHead = () => wrapper.find('thead');
const findTableHeadColumns = () => findTableHead().findAll('th');
const findStageEventTitle = (ev) => extendedWrapper(ev).findByTestId('vsa-stage-event-title');
const findStageTime = () => wrapper.findByTestId('vsa-stage-event-time');
const findIcon = (name) => wrapper.findByTestId(`${name}-icon`);

function createComponent(props = {}, shallow = false) {
  const func = shallow ? shallowMount : mount;
  return extendedWrapper(
    func(StageTable, {
      propsData: {
        isLoading: false,
        stageEvents: issueEventItems,
        noDataSvgPath,
        selectedStage: issueStage,
        pagination,
        ...props,
      },
      stubs: {
        GlLoadingIcon,
        GlEmptyState,
      },
    }),
  );
}

describe('StageTable', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  describe('is loaded with data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('will render the correct events', () => {
      const evs = findStageEvents();
      expect(evs).toHaveLength(issueEventItems.length);

      const titles = evs.wrappers.map((ev) => findStageEventTitle(ev).text());
      issueEventItems.forEach((ev, index) => {
        expect(titles[index]).toBe(ev.title);
      });
    });

    it('will not display the default data message', () => {
      expect(wrapper.html()).not.toContain(notEnoughDataError);
    });
  });

  describe('with minimal stage data', () => {
    beforeEach(() => {
      wrapper = createComponent({ currentStage: { title: 'New stage title' } });
    });

    it('will render the correct events', () => {
      const evs = findStageEvents();
      expect(evs).toHaveLength(issueEventItems.length);

      const titles = evs.wrappers.map((ev) => findStageEventTitle(ev).text());
      issueEventItems.forEach((ev, index) => {
        expect(titles[index]).toBe(ev.title);
      });
    });
  });

  describe('default event', () => {
    beforeEach(() => {
      wrapper = createComponent({
        stageEvents: [{ ...firstIssueEvent }],
        selectedStage: { ...issueStage, custom: false },
      });
    });

    it('will render the event title', () => {
      expect(wrapper.findByTestId('vsa-stage-event-title').text()).toBe(firstIssueEvent.title);
    });

    it('will set the workflow title to "Issues"', () => {
      expect(findTableHead().text()).toContain('Issues');
    });

    it('does not render the fork icon', () => {
      expect(findIcon('fork').exists()).toBe(false);
    });

    it('does not render the branch icon', () => {
      expect(findIcon('commit').exists()).toBe(false);
    });

    it('will render the total time', () => {
      const createdAt = firstIssueEvent.createdAt.replace(' ago', '');
      expect(findStageTime().text()).toBe(createdAt);
    });

    it('will render the author', () => {
      expect(wrapper.findByTestId('vsa-stage-event-author').text()).toContain(
        firstIssueEvent.author.name,
      );
    });

    it('will render the created at date', () => {
      expect(wrapper.findByTestId('vsa-stage-event-date').text()).toContain(
        firstIssueEvent.createdAt,
      );
    });
  });

  describe('merge request event', () => {
    beforeEach(() => {
      wrapper = createComponent({
        stageEvents: [{ ...firstReviewEvent }],
        selectedStage: { ...reviewStage, custom: false },
      });
    });

    it('will set the workflow title to "Merge requests"', () => {
      expect(findTableHead().text()).toContain('Merge requests');
      expect(findTableHead().text()).not.toContain('Issues');
    });
  });

  describe('isLoading = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ isLoading: true }, true);
    });

    it('will display the loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('will not display pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('with no stageEvents', () => {
    beforeEach(() => {
      wrapper = createComponent({ stageEvents: [] });
    });

    it('will render the empty state', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('will display the default no data message', () => {
      expect(wrapper.html()).toContain(notEnoughDataError);
    });

    it('will not display the pagination component', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('emptyStateTitle set', () => {
    beforeEach(() => {
      wrapper = createComponent({ stageEvents: [], emptyStateTitle });
    });

    it('will display the custom message', () => {
      expect(wrapper.html()).not.toContain(notEnoughDataError);
      expect(wrapper.html()).toContain(emptyStateTitle);
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
      wrapper.destroy();
    });

    it('will display the pagination component', () => {
      expect(findPagination().exists()).toBe(true);
    });

    it('clicking prev or next will emit an event', async () => {
      expect(wrapper.emitted('handleUpdatePagination')).toBeUndefined();

      findPagination().vm.$emit('input', 2);
      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('handleUpdatePagination')[0]).toEqual([{ page: 2 }]);
    });

    it('clicking prev or next will send tracking information', () => {
      findPagination().vm.$emit('input', 2);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', { label: 'pagination' });
    });

    describe('with `hasNextPage=false', () => {
      beforeEach(() => {
        wrapper = createComponent({ pagination: { page: 1, hasNextPage: false } });
      });

      it('will not display the pagination component', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });
  });

  describe('Sorting', () => {
    const triggerTableSort = (sortDesc = true) =>
      findTable().vm.$emit('sort-changed', {
        sortBy: PAGINATION_SORT_FIELD_DURATION,
        sortDesc,
      });

    beforeEach(() => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
      wrapper.destroy();
    });

    it('can sort the table by each column', () => {
      findTableHeadColumns().wrappers.forEach((w) => {
        expect(w.attributes('aria-sort')).toBe('none');
      });
    });

    it('clicking a table column will send tracking information', () => {
      triggerTableSort();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'sort_duration_desc',
      });
    });

    it('clicking a table column will update the sort field', () => {
      expect(wrapper.emitted('handleUpdatePagination')).toBeUndefined();
      triggerTableSort();

      expect(wrapper.emitted('handleUpdatePagination')[0]).toEqual([
        {
          direction: 'desc',
          sort: 'duration',
        },
      ]);
    });

    it('with sortDesc=false will toggle the direction field', async () => {
      expect(wrapper.emitted('handleUpdatePagination')).toBeUndefined();
      triggerTableSort(false);

      expect(wrapper.emitted('handleUpdatePagination')[0]).toEqual([
        {
          direction: 'asc',
          sort: 'duration',
        },
      ]);
    });

    describe('with sortable=false', () => {
      beforeEach(() => {
        wrapper = createComponent({ sortable: false });
      });

      it('cannot sort the table', () => {
        findTableHeadColumns().wrappers.forEach((w) => {
          expect(w.attributes('aria-sort')).toBeUndefined();
        });
      });
    });
  });
});
