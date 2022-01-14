import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import NewIssueDropdown from '~/issues_list/components/new_issue_dropdown.vue';
import searchProjectsQuery from '~/issues_list/queries/search_projects.query.graphql';
import { DASH_SCOPE, joinPaths } from '~/lib/utils/url_utility';
import {
  emptySearchProjectsQueryResponse,
  project1,
  project3,
  searchProjectsQueryResponse,
} from '../mock_data';

describe('NewIssueDropdown component', () => {
  let wrapper;

  const localVue = createLocalVue();
  localVue.use(VueApollo);

  const mountComponent = ({
    search = '',
    queryResponse = searchProjectsQueryResponse,
    mountFn = shallowMount,
  } = {}) => {
    const requestHandlers = [[searchProjectsQuery, jest.fn().mockResolvedValue(queryResponse)]];
    const apolloProvider = createMockApollo(requestHandlers);

    return mountFn(NewIssueDropdown, {
      localVue,
      apolloProvider,
      provide: {
        fullPath: 'mushroom-kingdom',
      },
      data() {
        return { search };
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findInput = () => wrapper.findComponent(GlSearchBoxByType);
  const showDropdown = async () => {
    findDropdown().vm.$emit('shown');
    await wrapper.vm.$apollo.queries.projects.refetch();
    jest.runOnlyPendingTimers();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a split dropdown', () => {
    wrapper = mountComponent();

    expect(findDropdown().props('split')).toBe(true);
  });

  it('renders a label for the dropdown toggle button', () => {
    wrapper = mountComponent();

    expect(findDropdown().attributes('toggle-text')).toBe(NewIssueDropdown.i18n.toggleButtonLabel);
  });

  it('focuses on input when dropdown is shown', async () => {
    wrapper = mountComponent({ mountFn: mount });

    const inputSpy = jest.spyOn(findInput().vm, 'focusInput');

    await showDropdown();

    expect(inputSpy).toHaveBeenCalledTimes(1);
  });

  it('renders projects with issues enabled', async () => {
    wrapper = mountComponent({ mountFn: mount });

    await showDropdown();

    const listItems = wrapper.findAll('li');

    expect(listItems.at(0).text()).toBe(project1.nameWithNamespace);
    expect(listItems.at(1).text()).toBe(project3.nameWithNamespace);
  });

  it('renders `No matches found` when there are no matches', async () => {
    wrapper = mountComponent({
      search: 'no matches',
      queryResponse: emptySearchProjectsQueryResponse,
      mountFn: mount,
    });

    await showDropdown();

    expect(wrapper.find('li').text()).toBe(NewIssueDropdown.i18n.noMatchesFound);
  });

  describe('when no project is selected', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('dropdown button is not a link', () => {
      expect(findDropdown().attributes('split-href')).toBeUndefined();
    });

    it('displays default text on the dropdown button', () => {
      expect(findDropdown().props('text')).toBe(NewIssueDropdown.i18n.defaultDropdownText);
    });
  });

  describe('when a project is selected', () => {
    beforeEach(async () => {
      wrapper = mountComponent({ mountFn: mount });

      await showDropdown();

      wrapper.findComponent(GlDropdownItem).vm.$emit('click', project1);
    });

    it('dropdown button is a link', () => {
      const href = joinPaths(project1.webUrl, DASH_SCOPE, 'issues/new');

      expect(findDropdown().attributes('split-href')).toBe(href);
    });

    it('displays project name on the dropdown button', () => {
      expect(findDropdown().props('text')).toBe(`New issue in ${project1.name}`);
    });
  });
});
