import { GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import BlobButtonGroup from '~/repository/components/blob_button_group.vue';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import BlobEdit from '~/repository/components/blob_edit.vue';
import ForkSuggestion from '~/repository/components/fork_suggestion.vue';
import { loadViewer, viewerProps } from '~/repository/components/blob_viewers';
import DownloadViewer from '~/repository/components/blob_viewers/download_viewer.vue';
import EmptyViewer from '~/repository/components/blob_viewers/empty_viewer.vue';
import SourceViewer from '~/vue_shared/components/source_viewer.vue';
import blobInfoQuery from '~/repository/queries/blob_info.query.graphql';
import { redirectTo } from '~/lib/utils/url_utility';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  simpleViewerMock,
  richViewerMock,
  projectMock,
  userPermissionsMock,
  propsMock,
  refMock,
} from '../mock_data';

jest.mock('~/repository/components/blob_viewers');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/common_utils');

let wrapper;
let mockResolver;

const localVue = createLocalVue();
const mockAxios = new MockAdapter(axios);

const createComponent = async (mockData = {}, mountFn = shallowMount) => {
  localVue.use(VueApollo);

  const {
    blob = simpleViewerMock,
    empty = projectMock.repository.empty,
    pushCode = userPermissionsMock.pushCode,
    forkProject = userPermissionsMock.forkProject,
    downloadCode = userPermissionsMock.downloadCode,
    createMergeRequestIn = userPermissionsMock.createMergeRequestIn,
    isBinary,
    inject = {},
  } = mockData;

  const project = {
    ...projectMock,
    userPermissions: {
      pushCode,
      forkProject,
      downloadCode,
      createMergeRequestIn,
    },
    repository: {
      empty,
      blobs: { nodes: [blob] },
    },
  };

  mockResolver = jest.fn().mockResolvedValue({
    data: { isBinary, project },
  });

  const fakeApollo = createMockApollo([[blobInfoQuery, mockResolver]]);

  wrapper = extendedWrapper(
    mountFn(BlobContentViewer, {
      localVue,
      apolloProvider: fakeApollo,
      propsData: propsMock,
      mixins: [{ data: () => ({ ref: refMock }) }],
      provide: { ...inject },
    }),
  );

  wrapper.setData({ project, isBinary });

  await waitForPromises();
};

describe('Blob content viewer component', () => {
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBlobHeader = () => wrapper.findComponent(BlobHeader);
  const findBlobEdit = () => wrapper.findComponent(BlobEdit);
  const findPipelineEditor = () => wrapper.findByTestId('pipeline-editor');
  const findBlobContent = () => wrapper.findComponent(BlobContent);
  const findBlobButtonGroup = () => wrapper.findComponent(BlobButtonGroup);
  const findForkSuggestion = () => wrapper.findComponent(ForkSuggestion);

  beforeEach(() => {
    gon.features = { highlightJs: true };
    isLoggedIn.mockReturnValue(true);
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.reset();
  });

  it('renders a GlLoadingIcon component', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('simple viewer', () => {
    it('renders a BlobHeader component', async () => {
      await createComponent();

      expect(findBlobHeader().props('activeViewerType')).toEqual('simple');
      expect(findBlobHeader().props('hasRenderError')).toEqual(false);
      expect(findBlobHeader().props('hideViewerSwitcher')).toEqual(true);
      expect(findBlobHeader().props('blob')).toEqual(simpleViewerMock);
    });

    it('renders a BlobContent component', async () => {
      await createComponent();

      expect(findBlobContent().props('isRawContent')).toBe(true);
      expect(findBlobContent().props('activeViewer')).toEqual({
        fileType: 'text',
        tooLarge: false,
        type: 'simple',
        renderError: null,
      });
    });

    describe('legacy viewers', () => {
      it('loads a legacy viewer when a viewer component is not available', async () => {
        await createComponent({ blob: { ...simpleViewerMock, fileType: 'unknown' } });

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0].url).toEqual('some_file.js?format=json&viewer=simple');
      });
    });
  });

  describe('rich viewer', () => {
    it('renders a BlobHeader component', async () => {
      await createComponent({ blob: richViewerMock });

      expect(findBlobHeader().props('activeViewerType')).toEqual('rich');
      expect(findBlobHeader().props('hasRenderError')).toEqual(false);
      expect(findBlobHeader().props('hideViewerSwitcher')).toEqual(false);
      expect(findBlobHeader().props('blob')).toEqual(richViewerMock);
    });

    it('renders a BlobContent component', async () => {
      await createComponent({ blob: richViewerMock });

      expect(findBlobContent().props('isRawContent')).toBe(true);
      expect(findBlobContent().props('activeViewer')).toEqual({
        fileType: 'markup',
        tooLarge: false,
        type: 'rich',
        renderError: null,
      });
    });

    it('updates viewer type when viewer changed is clicked', async () => {
      await createComponent({ blob: richViewerMock });

      expect(findBlobContent().props('activeViewer')).toEqual(
        expect.objectContaining({
          type: 'rich',
        }),
      );
      expect(findBlobHeader().props('activeViewerType')).toEqual('rich');

      findBlobHeader().vm.$emit('viewer-changed', 'simple');
      await nextTick();

      expect(findBlobHeader().props('activeViewerType')).toEqual('simple');
      expect(findBlobContent().props('activeViewer')).toEqual(
        expect.objectContaining({
          type: 'simple',
        }),
      );
    });
  });

  describe('legacy viewers', () => {
    it('loads a legacy viewer when a viewer component is not available', async () => {
      await createComponent({ blob: { ...richViewerMock, fileType: 'unknown' } });

      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].url).toEqual('some_file.js?format=json&viewer=rich');
    });
  });

  describe('Blob viewer', () => {
    afterEach(() => {
      loadViewer.mockRestore();
      viewerProps.mockRestore();
    });

    it('does not render a BlobContent component if a Blob viewer is available', async () => {
      loadViewer.mockReturnValue(() => true);
      await createComponent({ blob: richViewerMock });

      expect(findBlobContent().exists()).toBe(false);
    });

    it.each`
      viewer        | loadViewerReturnValue | viewerPropsReturnValue
      ${'empty'}    | ${EmptyViewer}        | ${{}}
      ${'download'} | ${DownloadViewer}     | ${{ filePath: '/some/file/path', fileName: 'test.js', fileSize: 100 }}
      ${'text'}     | ${SourceViewer}       | ${{ content: 'test', autoDetect: true }}
    `(
      'renders viewer component for $viewer files',
      async ({ viewer, loadViewerReturnValue, viewerPropsReturnValue }) => {
        loadViewer.mockReturnValue(loadViewerReturnValue);
        viewerProps.mockReturnValue(viewerPropsReturnValue);

        createComponent({
          blob: {
            ...simpleViewerMock,
            fileType: 'null',
            simpleViewer: {
              ...simpleViewerMock.simpleViewer,
              fileType: viewer,
            },
          },
        });

        await nextTick();

        expect(loadViewer).toHaveBeenCalledWith(viewer);
        expect(wrapper.findComponent(loadViewerReturnValue).exists()).toBe(true);
      },
    );
  });

  describe('BlobHeader action slot', () => {
    const { ideEditPath, editBlobPath } = simpleViewerMock;

    it('renders BlobHeaderEdit buttons in simple viewer', async () => {
      await createComponent({ inject: { BlobContent: true, BlobReplace: true } }, mount);

      expect(findBlobEdit().props()).toMatchObject({
        editPath: editBlobPath,
        webIdePath: ideEditPath,
        showEditButton: true,
      });
    });

    it('renders BlobHeaderEdit button in rich viewer', async () => {
      await createComponent({ blob: richViewerMock }, mount);

      expect(findBlobEdit().props()).toMatchObject({
        editPath: editBlobPath,
        webIdePath: ideEditPath,
        showEditButton: true,
      });
    });

    it('renders BlobHeaderEdit button for binary files', async () => {
      await createComponent({ blob: richViewerMock, isBinary: true }, mount);

      expect(findBlobEdit().props()).toMatchObject({
        editPath: editBlobPath,
        webIdePath: ideEditPath,
        showEditButton: false,
      });
    });

    it('renders Pipeline Editor button for .gitlab-ci files', async () => {
      const pipelineEditorPath = 'some/path/.gitlab-ce';
      const blob = { ...simpleViewerMock, pipelineEditorPath };
      await createComponent({ blob, inject: { BlobContent: true, BlobReplace: true } }, mount);

      expect(findPipelineEditor().exists()).toBe(true);
      expect(findPipelineEditor().attributes('href')).toBe(pipelineEditorPath);
    });

    describe('blob header binary file', () => {
      it('passes the correct isBinary value when viewing a binary file', async () => {
        await createComponent({ blob: richViewerMock, isBinary: true });

        expect(findBlobHeader().props('isBinary')).toBe(true);
      });

      it('passes the correct header props when viewing a non-text file', async () => {
        await createComponent(
          {
            blob: {
              ...simpleViewerMock,
              simpleViewer: {
                ...simpleViewerMock.simpleViewer,
                fileType: 'image',
              },
            },
            isBinary: true,
          },
          mount,
        );

        expect(findBlobHeader().props('hideViewerSwitcher')).toBe(true);
        expect(findBlobHeader().props('isBinary')).toBe(true);
        expect(findBlobEdit().props('showEditButton')).toBe(false);
      });
    });

    describe('BlobButtonGroup', () => {
      const { name, path, replacePath, webPath } = simpleViewerMock;
      const {
        userPermissions: { pushCode, downloadCode },
        repository: { empty },
      } = projectMock;

      afterEach(() => {
        delete gon.current_user_id;
        delete gon.current_username;
      });

      it('renders component', async () => {
        window.gon.current_user_id = 1;
        window.gon.current_username = 'root';

        await createComponent({ pushCode, downloadCode, empty }, mount);

        expect(findBlobButtonGroup().props()).toMatchObject({
          name,
          path,
          replacePath,
          deletePath: webPath,
          canPushCode: pushCode,
          canLock: true,
          isLocked: true,
          emptyRepo: empty,
        });
      });

      it.each`
        canPushCode | canDownloadCode | username   | canLock
        ${true}     | ${true}         | ${'root'}  | ${true}
        ${false}    | ${true}         | ${'root'}  | ${false}
        ${true}     | ${false}        | ${'root'}  | ${false}
        ${true}     | ${true}         | ${'peter'} | ${false}
      `(
        'passes the correct lock states',
        async ({ canPushCode, canDownloadCode, username, canLock }) => {
          gon.current_username = username;

          await createComponent(
            {
              pushCode: canPushCode,
              downloadCode: canDownloadCode,
              empty,
            },
            mount,
          );

          expect(findBlobButtonGroup().props('canLock')).toBe(canLock);
        },
      );

      it('does not render if not logged in', async () => {
        isLoggedIn.mockReturnValueOnce(false);

        await createComponent();

        expect(findBlobButtonGroup().exists()).toBe(false);
      });
    });
  });

  describe('blob info query', () => {
    it('is called with originalBranch value if the prop has a value', async () => {
      await createComponent({ inject: { originalBranch: 'some-branch' } });

      expect(mockResolver).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'some-branch',
        }),
      );
    });

    it('is called with ref value if the originalBranch prop has no value', async () => {
      await createComponent();

      expect(mockResolver).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'default-ref',
        }),
      );
    });
  });

  describe('edit blob', () => {
    beforeEach(() => createComponent({}, mount));

    it('simple edit redirects to the simple editor', () => {
      findBlobEdit().vm.$emit('edit', 'simple');
      expect(redirectTo).toHaveBeenCalledWith(simpleViewerMock.editBlobPath);
    });

    it('IDE edit redirects to the IDE editor', () => {
      findBlobEdit().vm.$emit('edit', 'ide');
      expect(redirectTo).toHaveBeenCalledWith(simpleViewerMock.ideEditPath);
    });

    it.each`
      loggedIn | canModifyBlob | createMergeRequestIn | forkProject | showForkSuggestion
      ${true}  | ${false}      | ${true}              | ${true}     | ${true}
      ${false} | ${false}      | ${true}              | ${true}     | ${false}
      ${true}  | ${true}       | ${false}             | ${true}     | ${false}
      ${true}  | ${true}       | ${true}              | ${false}    | ${false}
    `(
      'shows/hides a fork suggestion according to a set of conditions',
      async ({
        loggedIn,
        canModifyBlob,
        createMergeRequestIn,
        forkProject,
        showForkSuggestion,
      }) => {
        isLoggedIn.mockReturnValueOnce(loggedIn);
        await createComponent(
          {
            blob: { ...simpleViewerMock, canModifyBlob },
            createMergeRequestIn,
            forkProject,
          },
          mount,
        );

        findBlobEdit().vm.$emit('edit', 'simple');
        await nextTick();

        expect(findForkSuggestion().exists()).toBe(showForkSuggestion);
      },
    );
  });
});
