import {
  GlSprintf,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffStatsDropdown, { i18n } from '~/vue_shared/components/diff_stats_dropdown.vue';

jest.mock('fuzzaldrin-plus', () => ({
  filter: jest.fn().mockReturnValue([]),
}));

const mockFiles = [
  {
    added: 0,
    href: '#a5cc2925ca8258af241be7e5b0381edf30266302',
    icon: 'file-modified',
    iconColor: '',
    name: '',
    path: '.gitignore',
    removed: 3,
    title: '.gitignore',
  },
  {
    added: 1,
    href: '#fa288d1472d29beccb489a676f68739ad365fc47',
    icon: 'file-modified',
    iconColor: 'danger',
    name: 'package-lock.json',
    path: 'lock/file/path',
    removed: 1,
  },
];

describe('Diff Stats Dropdown', () => {
  let wrapper;

  const createComponent = ({ changed = 0, added = 0, deleted = 0, files = [] } = {}) => {
    wrapper = shallowMountExtended(DiffStatsDropdown, {
      propsData: {
        changed,
        added,
        deleted,
        files,
      },
      stubs: {
        GlSprintf,
        GlDropdown,
      },
    });
  };

  const findChanged = () => wrapper.findComponent(GlDropdown);
  const findChangedFiles = () => findChanged().findAllComponents(GlDropdownItem);
  const findNoFilesText = () => findChanged().findComponent(GlDropdownText);
  const findCollapsed = () => wrapper.findByTestId('diff-stats-additions-deletions-expanded');
  const findExpanded = () => wrapper.findByTestId('diff-stats-additions-deletions-collapsed');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  describe('file item', () => {
    beforeEach(() => {
      createComponent({ files: mockFiles });
    });

    it('when no file name provided ', () => {
      expect(findChangedFiles().at(0).text()).toContain(i18n.noFileNameAvailable);
    });

    it('when all file data is available', () => {
      const fileData = findChangedFiles().at(1);
      const fileText = findChangedFiles().at(1).text();
      expect(fileText).toContain(mockFiles[1].name);
      expect(fileText).toContain(mockFiles[1].path);
      expect(fileData.props()).toMatchObject({
        iconName: mockFiles[1].icon,
        iconColor: mockFiles[1].iconColor,
      });
    });

    it('when no files changed', () => {
      createComponent({ files: [] });
      expect(findNoFilesText().text()).toContain(i18n.noFilesFound);
    });
  });

  describe.each`
    changed | added | deleted | expectedDropdownHeader | expectedAddedDeletedExpanded | expectedAddedDeletedCollapsed
    ${0}    | ${0}  | ${0}    | ${'0 changed files'}   | ${'+0 -0'}                   | ${'with 0 additions and 0 deletions'}
    ${2}    | ${0}  | ${2}    | ${'2 changed files'}   | ${'+0 -2'}                   | ${'with 0 additions and 2 deletions'}
    ${2}    | ${2}  | ${0}    | ${'2 changed files'}   | ${'+2 -0'}                   | ${'with 2 additions and 0 deletions'}
    ${2}    | ${1}  | ${1}    | ${'2 changed files'}   | ${'+1 -1'}                   | ${'with 1 addition and 1 deletion'}
    ${1}    | ${0}  | ${1}    | ${'1 changed file'}    | ${'+0 -1'}                   | ${'with 0 additions and 1 deletion'}
    ${1}    | ${1}  | ${0}    | ${'1 changed file'}    | ${'+1 -0'}                   | ${'with 1 addition and 0 deletions'}
    ${4}    | ${2}  | ${2}    | ${'4 changed files'}   | ${'+2 -2'}                   | ${'with 2 additions and 2 deletions'}
  `(
    'when there are $changed changed file(s), $added added and $deleted deleted file(s)',
    ({
      changed,
      added,
      deleted,
      expectedDropdownHeader,
      expectedAddedDeletedExpanded,
      expectedAddedDeletedCollapsed,
    }) => {
      beforeAll(() => {
        createComponent({ changed, added, deleted });
      });

      afterAll(() => {
        wrapper.destroy();
      });

      it(`dropdown header should be '${expectedDropdownHeader}'`, () => {
        expect(findChanged().props('text')).toBe(expectedDropdownHeader);
      });

      it(`added and deleted count in expanded section should be '${expectedAddedDeletedExpanded}'`, () => {
        expect(findExpanded().text()).toBe(expectedAddedDeletedExpanded);
      });

      it(`added and deleted count in collapsed section should be '${expectedAddedDeletedCollapsed}'`, () => {
        expect(findCollapsed().text()).toBe(expectedAddedDeletedCollapsed);
      });
    },
  );

  describe('fuzzy file search', () => {
    beforeEach(() => {
      createComponent({ files: mockFiles });
    });

    it('should call `fuzzaldrinPlus.filter` to search for files when the search query is NOT empty', async () => {
      const searchStr = 'file name';
      findSearchBox().vm.$emit('input', searchStr);
      await nextTick();
      expect(fuzzaldrinPlus.filter).toHaveBeenCalledWith(mockFiles, searchStr, { key: 'name' });
    });

    it('should NOT call `fuzzaldrinPlus.filter` to search for files when the search query is empty', async () => {
      const searchStr = '';
      findSearchBox().vm.$emit('input', searchStr);
      await nextTick();
      expect(fuzzaldrinPlus.filter).not.toHaveBeenCalled();
    });
  });

  describe('selecting file dropdown item', () => {
    beforeEach(() => {
      createComponent({ files: mockFiles });
    });

    it('updates the URL ', () => {
      findChangedFiles().at(0).vm.$emit('click');
      expect(window.location.hash).toBe(mockFiles[0].href);
      findChangedFiles().at(1).vm.$emit('click');
      expect(window.location.hash).toBe(mockFiles[1].href);
    });
  });

  describe('on dropdown open', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should set the search input focus', () => {
      wrapper.vm.$refs.search.focusInput = jest.fn();
      findChanged().vm.$emit('shown');

      expect(wrapper.vm.$refs.search.focusInput).toHaveBeenCalled();
    });
  });
});
