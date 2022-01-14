import { shallowMount } from '@vue/test-utils';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import FilePreview from '~/repository/components/preview/index.vue';
import FileTable from '~/repository/components/table/index.vue';
import TreeContent from 'jh_else_ce/repository/components/tree_content.vue';
import { loadCommits, isRequested, resetRequestedCommits } from '~/repository/commits_service';

jest.mock('~/repository/commits_service', () => ({
  loadCommits: jest.fn(() => Promise.resolve()),
  isRequested: jest.fn(),
  resetRequestedCommits: jest.fn(),
}));

let vm;
let $apollo;

function factory(path, data = () => ({})) {
  $apollo = {
    query: jest.fn().mockReturnValue(Promise.resolve({ data: data() })),
  };

  vm = shallowMount(TreeContent, {
    propsData: {
      path,
    },
    mocks: {
      $apollo,
    },
    provide: {
      glFeatures: {
        increasePageSizeExponentially: true,
        paginatedTreeGraphqlQuery: true,
        lazyLoadCommits: true,
      },
    },
  });
}

describe('Repository table component', () => {
  const findFileTable = () => vm.find(FileTable);

  afterEach(() => {
    vm.destroy();
  });

  it('renders file preview', async () => {
    factory('/');

    vm.setData({ entries: { blobs: [{ name: 'README.md' }] } });

    await vm.vm.$nextTick();

    expect(vm.find(FilePreview).exists()).toBe(true);
  });

  it('trigger fetchFiles and resetRequestedCommits when mounted', async () => {
    factory('/');

    jest.spyOn(vm.vm, 'fetchFiles').mockImplementation(() => {});

    await vm.vm.$nextTick();

    expect(vm.vm.fetchFiles).toHaveBeenCalled();
    expect(resetRequestedCommits).toHaveBeenCalled();
  });

  describe('normalizeData', () => {
    it('normalizes edge nodes', () => {
      factory('/');

      const output = vm.vm.normalizeData('blobs', { nodes: ['1', '2'] });

      expect(output).toEqual(['1', '2']);
    });
  });

  describe('hasNextPage', () => {
    it('returns undefined when hasNextPage is false', () => {
      factory('/');

      const output = vm.vm.hasNextPage({
        trees: { pageInfo: { hasNextPage: false } },
        submodules: { pageInfo: { hasNextPage: false } },
        blobs: { pageInfo: { hasNextPage: false } },
      });

      expect(output).toBe(undefined);
    });

    it('returns pageInfo object when hasNextPage is true', () => {
      factory('/');

      const output = vm.vm.hasNextPage({
        trees: { pageInfo: { hasNextPage: false } },
        submodules: { pageInfo: { hasNextPage: false } },
        blobs: { pageInfo: { hasNextPage: true, nextCursor: 'test' } },
      });

      expect(output).toEqual({ hasNextPage: true, nextCursor: 'test' });
    });
  });

  describe('FileTable showMore', () => {
    describe('when is present', () => {
      beforeEach(async () => {
        factory('/');
      });

      it('is changes hasShowMore to false when "showMore" event is emitted', async () => {
        findFileTable().vm.$emit('showMore');

        await vm.vm.$nextTick();

        expect(vm.vm.hasShowMore).toBe(false);
      });

      it('changes clickedShowMore when "showMore" event is emitted', async () => {
        findFileTable().vm.$emit('showMore');

        await vm.vm.$nextTick();

        expect(vm.vm.clickedShowMore).toBe(true);
      });

      it('triggers fetchFiles when "showMore" event is emitted', () => {
        jest.spyOn(vm.vm, 'fetchFiles');

        findFileTable().vm.$emit('showMore');

        expect(vm.vm.fetchFiles).toHaveBeenCalled();
      });
    });

    it('is not rendered if less than 1000 files', async () => {
      factory('/');

      vm.setData({ fetchCounter: 5, clickedShowMore: false });

      await vm.vm.$nextTick();

      expect(vm.vm.hasShowMore).toBe(false);
    });

    it.each`
      totalBlobs | pagesLoaded | limitReached
      ${900}     | ${1}        | ${false}
      ${1000}    | ${1}        | ${true}
      ${1002}    | ${1}        | ${true}
      ${1002}    | ${2}        | ${false}
      ${1900}    | ${2}        | ${false}
      ${2000}    | ${2}        | ${true}
    `('has limit of 1000 entries per page', async ({ totalBlobs, pagesLoaded, limitReached }) => {
      factory('/');

      const blobs = new Array(totalBlobs).fill('fakeBlob');
      vm.setData({ entries: { blobs }, pagesLoaded });

      await vm.vm.$nextTick();

      expect(findFileTable().props('hasMore')).toBe(limitReached);
    });

    it.each`
      fetchCounter | pageSize
      ${0}         | ${10}
      ${2}         | ${30}
      ${4}         | ${50}
      ${6}         | ${70}
      ${8}         | ${90}
      ${10}        | ${100}
      ${20}        | ${100}
      ${100}       | ${100}
      ${200}       | ${100}
    `('exponentially increases page size, to a maximum of 100', ({ fetchCounter, pageSize }) => {
      factory('/');
      vm.setData({ fetchCounter });

      vm.vm.fetchFiles();

      expect($apollo.query).toHaveBeenCalledWith({
        query: paginatedTreeQuery,
        variables: {
          pageSize,
          nextPageCursor: '',
          path: '/',
          projectPath: '',
          ref: '',
        },
      });
    });
  });

  describe('commit data', () => {
    const path = 'some/path';

    it('loads commit data for both top and bottom batches when row-appear event is emitted', () => {
      const rowNumber = 50;

      factory(path);
      findFileTable().vm.$emit('row-appear', rowNumber);

      expect(isRequested).toHaveBeenCalledWith(rowNumber);

      expect(loadCommits.mock.calls).toEqual([
        ['', path, '', rowNumber],
        ['', path, '', rowNumber - 25],
      ]);
    });

    it('loads commit data once if rowNumber is zero', () => {
      factory(path);
      findFileTable().vm.$emit('row-appear', 0);

      expect(loadCommits.mock.calls).toEqual([['', path, '', 0]]);
    });
  });
});
