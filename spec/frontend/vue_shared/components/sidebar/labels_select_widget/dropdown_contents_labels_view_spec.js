import {
  GlLoadingIcon,
  GlSearchBoxByType,
  GlDropdownItem,
  GlIntersectionObserver,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_labels_view.vue';
import projectLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/project_labels.query.graphql';
import LabelItem from '~/vue_shared/components/sidebar/labels_select_widget/label_item.vue';
import { mockConfig, workspaceLabelsQueryResponse } from './mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

const localSelectedLabels = [
  {
    color: '#2f7b2e',
    description: null,
    id: 'gid://gitlab/ProjectLabel/2',
    title: 'Label2',
  },
];

describe('DropdownContentsLabelsView', () => {
  let wrapper;

  const successfulQueryHandler = jest.fn().mockResolvedValue(workspaceLabelsQueryResponse);

  const findFirstLabel = () => wrapper.findAllComponents(GlDropdownItem).at(0);

  const createComponent = ({
    initialState = mockConfig,
    queryHandler = successfulQueryHandler,
    injected = {},
    searchKey = '',
  } = {}) => {
    const mockApollo = createMockApollo([[projectLabelsQuery, queryHandler]]);

    wrapper = shallowMount(DropdownContentsLabelsView, {
      apolloProvider: mockApollo,
      provide: {
        variant: DropdownVariant.Sidebar,
        ...injected,
      },
      propsData: {
        ...initialState,
        localSelectedLabels,
        searchKey,
        labelCreateType: 'project',
        workspaceType: 'project',
      },
      stubs: {
        GlSearchBoxByType,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findLabels = () => wrapper.findAllComponents(LabelItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findObserver = () => wrapper.findComponent(GlIntersectionObserver);

  const findLabelsList = () => wrapper.find('[data-testid="labels-list"]');
  const findNoResultsMessage = () => wrapper.find('[data-testid="no-results"]');

  async function makeObserverAppear() {
    await findObserver().vm.$emit('appear');
  }

  describe('when loading labels', () => {
    it('renders loading icon', async () => {
      createComponent();
      await makeObserverAppear();
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render labels list', async () => {
      createComponent();
      await makeObserverAppear();
      expect(findLabelsList().exists()).toBe(false);
    });
  });

  describe('when labels are loaded', () => {
    beforeEach(async () => {
      createComponent();
      await makeObserverAppear();
      await waitForPromises();
    });

    it('does not render loading icon', async () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders labels list', async () => {
      expect(findLabelsList().exists()).toBe(true);
      expect(findLabels()).toHaveLength(2);
    });
  });

  it('when search returns 0 results', async () => {
    createComponent({
      queryHandler: jest.fn().mockResolvedValue({
        data: {
          workspace: {
            labels: {
              nodes: [],
            },
          },
        },
      }),
      searchKey: '123',
    });
    await makeObserverAppear();
    await waitForPromises();
    await nextTick();

    expect(findNoResultsMessage().isVisible()).toBe(true);
  });

  it('calls `createFlash` when fetching labels failed', async () => {
    createComponent({ queryHandler: jest.fn().mockRejectedValue('Houston, we have a problem!') });
    await makeObserverAppear();
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });

  it('emits an `input` event on label click', async () => {
    createComponent();
    await makeObserverAppear();
    await waitForPromises();
    findFirstLabel().trigger('click');

    expect(wrapper.emitted('input')[0][0]).toEqual(expect.arrayContaining(localSelectedLabels));
  });

  it('does not trigger query when component did not appear', () => {
    createComponent();
    expect(findLoadingIcon().exists()).toBe(false);
    expect(findLabelsList().exists()).toBe(false);
    expect(successfulQueryHandler).not.toHaveBeenCalled();
  });
});
