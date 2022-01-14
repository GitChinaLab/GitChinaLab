import { GlIntersectionObserver, GlSkeletonLoader } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import JobsApp from '~/pipelines/components/jobs/jobs_app.vue';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import getPipelineJobsQuery from '~/pipelines/graphql/queries/get_pipeline_jobs.query.graphql';
import { mockPipelineJobsQueryResponse } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

jest.mock('~/flash');

describe('Jobs app', () => {
  let wrapper;
  let resolverSpy;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findJobsTable = () => wrapper.findComponent(JobsTable);

  const triggerInfiniteScroll = () =>
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');

  const createMockApolloProvider = (resolver) => {
    const requestHandlers = [[getPipelineJobsQuery, resolver]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = (resolver) => {
    wrapper = shallowMount(JobsApp, {
      provide: {
        fullPath: 'root/ci-project',
        pipelineIid: 1,
      },
      localVue,
      apolloProvider: createMockApolloProvider(resolver),
    });
  };

  beforeEach(() => {
    resolverSpy = jest.fn().mockResolvedValue(mockPipelineJobsQueryResponse);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the loading state', () => {
    createComponent(resolverSpy);

    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findJobsTable().exists()).toBe(false);
  });

  it('displays the jobs table', async () => {
    createComponent(resolverSpy);

    await waitForPromises();

    expect(findJobsTable().exists()).toBe(true);
    expect(findSkeletonLoader().exists()).toBe(false);
    expect(createFlash).not.toHaveBeenCalled();
  });

  it('handles job fetch error correctly', async () => {
    resolverSpy = jest.fn().mockRejectedValue(new Error('GraphQL error'));

    createComponent(resolverSpy);

    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith({
      message: 'An error occured while fetching the pipelines jobs.',
    });
  });

  it('handles infinite scrolling by calling fetchMore', async () => {
    createComponent(resolverSpy);

    await waitForPromises();

    triggerInfiniteScroll();

    expect(resolverSpy).toHaveBeenCalledWith({
      after: 'eyJpZCI6Ijg0NyJ9',
      fullPath: 'root/ci-project',
      iid: 1,
    });
  });

  it('does not display main loading state again after fetchMore', async () => {
    createComponent(resolverSpy);

    expect(findSkeletonLoader().exists()).toBe(true);

    await waitForPromises();

    triggerInfiniteScroll();

    expect(findSkeletonLoader().exists()).toBe(false);
  });
});
