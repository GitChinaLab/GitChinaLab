import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';

import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ListPage from '~/packages_and_registries/package_registry/pages/list.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';
import PackageSearch from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import OriginalPackageList from '~/packages_and_registries/package_registry/components/list/packages_list.vue';
import DeletePackage from '~/packages_and_registries/package_registry/components/functional/delete_package.vue';

import {
  PROJECT_RESOURCE_TYPE,
  GROUP_RESOURCE_TYPE,
  GRAPHQL_PAGE_SIZE,
  EMPTY_LIST_HELP_URL,
  PACKAGE_HELP_URL,
} from '~/packages_and_registries/package_registry/constants';

import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';

import { packagesListQuery, packageData, pagination } from '../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/flash');

const localVue = createLocalVue();

describe('PackagesListApp', () => {
  let wrapper;
  let apolloProvider;

  const defaultProvide = {
    emptyListIllustration: 'emptyListIllustration',
    isGroupPage: true,
    fullPath: 'gitlab-org',
  };

  const PackageList = {
    name: 'package-list',
    template: '<div><slot name="empty-state"></slot></div>',
    props: OriginalPackageList.props,
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const searchPayload = {
    sort: 'VERSION_DESC',
    filters: { packageName: 'foo', packageType: 'CONAN' },
  };

  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findSearch = () => wrapper.findComponent(PackageSearch);
  const findListComponent = () => wrapper.findComponent(PackageList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDeletePackage = () => wrapper.findComponent(DeletePackage);

  const mountComponent = ({
    resolver = jest.fn().mockResolvedValue(packagesListQuery()),
    provide = defaultProvide,
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [[getPackagesQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ListPage, {
      localVue,
      apolloProvider,
      provide,
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        GlSprintf,
        GlLink,
        PackageList,
        DeletePackage,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const waitForFirstRequest = () => {
    // emit a search update so the query is executed
    findSearch().vm.$emit('update', { sort: 'NAME_DESC', filters: [] });
    return waitForPromises();
  };

  it('does not execute the query without sort being set', () => {
    const resolver = jest.fn().mockResolvedValue(packagesListQuery());

    mountComponent({ resolver });

    expect(resolver).not.toHaveBeenCalled();
  });

  it('renders', async () => {
    mountComponent();

    await waitForFirstRequest();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a package title', async () => {
    mountComponent();

    await waitForFirstRequest();

    expect(findPackageTitle().exists()).toBe(true);
    expect(findPackageTitle().props()).toMatchObject({
      count: 2,
      helpUrl: PACKAGE_HELP_URL,
    });
  });

  describe('search component', () => {
    it('exists', () => {
      mountComponent();

      expect(findSearch().exists()).toBe(true);
    });

    it('on update triggers a new query with updated values', async () => {
      const resolver = jest.fn().mockResolvedValue(packagesListQuery());
      mountComponent({ resolver });

      findSearch().vm.$emit('update', searchPayload);

      await waitForPromises();

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({
          groupSort: searchPayload.sort,
          ...searchPayload.filters,
        }),
      );
    });
  });

  describe('list component', () => {
    let resolver;

    beforeEach(() => {
      resolver = jest.fn().mockResolvedValue(packagesListQuery());
      mountComponent({ resolver });

      return waitForFirstRequest();
    });

    it('exists and has the right props', () => {
      expect(findListComponent().props()).toMatchObject({
        list: expect.arrayContaining([expect.objectContaining({ id: packageData().id })]),
        isLoading: false,
        pageInfo: expect.objectContaining({ endCursor: pagination().endCursor }),
      });
    });

    it('when list emits next-page fetches the next set of records', () => {
      findListComponent().vm.$emit('next-page');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ after: pagination().endCursor, first: GRAPHQL_PAGE_SIZE }),
      );
    });

    it('when list emits prev-page fetches the prev set of records', () => {
      findListComponent().vm.$emit('prev-page');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ before: pagination().startCursor, last: GRAPHQL_PAGE_SIZE }),
      );
    });
  });

  describe.each`
    type                     | sortType
    ${PROJECT_RESOURCE_TYPE} | ${'sort'}
    ${GROUP_RESOURCE_TYPE}   | ${'groupSort'}
  `('$type query', ({ type, sortType }) => {
    let provide;
    let resolver;

    const isGroupPage = type === GROUP_RESOURCE_TYPE;

    beforeEach(() => {
      provide = { ...defaultProvide, isGroupPage };
      resolver = jest.fn().mockResolvedValue(packagesListQuery({ type }));
      mountComponent({ provide, resolver });
      return waitForFirstRequest();
    });

    it('succeeds', () => {
      expect(findPackageTitle().props('count')).toBe(2);
    });

    it('calls the resolver with the right parameters', () => {
      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ isGroupPage, [sortType]: 'NAME_DESC' }),
      );
    });
  });

  describe('empty state', () => {
    beforeEach(() => {
      const resolver = jest.fn().mockResolvedValue(packagesListQuery({ extend: { nodes: [] } }));
      mountComponent({ resolver });

      return waitForFirstRequest();
    });
    it('generate the correct empty list link', () => {
      const link = findListComponent().findComponent(GlLink);

      expect(link.attributes('href')).toBe(EMPTY_LIST_HELP_URL);
      expect(link.text()).toBe('publish and share your packages');
    });

    it('includes the right content on the default tab', () => {
      expect(findEmptyState().text()).toContain(ListPage.i18n.emptyPageTitle);
    });
  });

  describe('filter without results', () => {
    beforeEach(async () => {
      mountComponent();

      await waitForFirstRequest();

      findSearch().vm.$emit('update', searchPayload);

      return nextTick();
    });

    it('should show specific empty message', () => {
      expect(findEmptyState().text()).toContain(ListPage.i18n.noResultsTitle);
      expect(findEmptyState().text()).toContain(ListPage.i18n.widenFilters);
    });
  });

  describe('delete package', () => {
    it('exists and has the correct props', async () => {
      mountComponent();

      await waitForFirstRequest();

      expect(findDeletePackage().props()).toMatchObject({
        refetchQueries: [{ query: getPackagesQuery, variables: {} }],
        showSuccessAlert: true,
      });
    });

    it('deletePackage is bound to package-list package:delete event', async () => {
      mountComponent();

      await waitForFirstRequest();

      findListComponent().vm.$emit('package:delete', { id: 1 });

      expect(findDeletePackage().emitted('start')).toEqual([[]]);
    });

    it('start and end event set loading correctly', async () => {
      mountComponent();

      await waitForFirstRequest();

      findDeletePackage().vm.$emit('start');

      await nextTick();

      expect(findListComponent().props('isLoading')).toBe(true);

      findDeletePackage().vm.$emit('end');

      await nextTick();

      expect(findListComponent().props('isLoading')).toBe(false);
    });
  });
});
