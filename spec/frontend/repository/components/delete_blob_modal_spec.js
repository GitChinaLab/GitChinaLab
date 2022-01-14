import { GlFormTextarea, GlModal, GlFormInput, GlToggle, GlForm } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const initialProps = {
  modalId: 'Delete-blob',
  modalTitle: 'Delete File',
  deletePath: 'some/path',
  commitMessage: 'Delete File',
  targetBranch: 'some-target-branch',
  originalBranch: 'main',
  canPushCode: true,
  canPushToBranch: true,
  emptyRepo: false,
};

describe('DeleteBlobModal', () => {
  let wrapper;

  const createComponentFactory = (mountFn) => (props = {}) => {
    wrapper = mountFn(DeleteBlobModal, {
      propsData: {
        ...initialProps,
        ...props,
      },
      attrs: {
        static: true,
        visible: true,
      },
    });
  };

  const createComponent = createComponentFactory(shallowMount);
  const createFullComponent = createComponentFactory(mount);

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => findModal().findComponent(GlForm);
  const findCommitTextarea = () => findForm().findComponent(GlFormTextarea);
  const findTargetInput = () => findForm().findComponent(GlFormInput);
  const findCommitHint = () => wrapper.find('[data-testid="hint"]');

  const fillForm = async (inputValue = {}) => {
    const { targetText, commitText } = inputValue;

    await findTargetInput().vm.$emit('input', targetText);
    await findCommitTextarea().vm.$emit('input', commitText);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders Modal component', () => {
    createComponent();

    const { modalTitle: title } = initialProps;

    expect(findModal().props()).toMatchObject({
      title,
      size: 'md',
      actionPrimary: {
        text: 'Delete file',
      },
      actionCancel: {
        text: 'Cancel',
      },
    });
  });

  describe('form', () => {
    it('gets passed the path for action attribute', () => {
      createComponent();
      expect(findForm().attributes('action')).toBe(initialProps.deletePath);
    });

    it.each`
      component         | defaultValue                  | canPushCode | targetBranch                 | originalBranch                 | exist
      ${GlFormTextarea} | ${initialProps.commitMessage} | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${GlFormInput}    | ${initialProps.targetBranch}  | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${GlFormInput}    | ${undefined}                  | ${false}    | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${false}
      ${GlToggle}       | ${'true'}                     | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${GlToggle}       | ${undefined}                  | ${true}     | ${'same-branch'}             | ${'same-branch'}               | ${false}
    `(
      'has the correct form fields ',
      ({ component, defaultValue, canPushCode, targetBranch, originalBranch, exist }) => {
        createComponent({
          canPushCode,
          targetBranch,
          originalBranch,
        });
        const formField = wrapper.findComponent(component);

        if (!exist) {
          expect(formField.exists()).toBe(false);
          return;
        }

        expect(formField.exists()).toBe(true);
        expect(formField.attributes('value')).toBe(defaultValue);
      },
    );

    it.each`
      input                     | value                          | emptyRepo | canPushCode | canPushToBranch | exist
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${false}  | ${true}     | ${true}         | ${true}
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${true}   | ${false}    | ${true}         | ${true}
      ${'_method'}              | ${'delete'}                    | ${false}  | ${true}     | ${true}         | ${true}
      ${'_method'}              | ${'delete'}                    | ${true}   | ${false}    | ${true}         | ${true}
      ${'original_branch'}      | ${initialProps.originalBranch} | ${false}  | ${true}     | ${true}         | ${true}
      ${'original_branch'}      | ${undefined}                   | ${true}   | ${true}     | ${true}         | ${false}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${true}         | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${true}     | ${true}         | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${false}        | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${true}         | ${true}
      ${'create_merge_request'} | ${undefined}                   | ${true}   | ${false}    | ${true}         | ${false}
    `(
      'passes $input as a hidden input with the correct value',
      ({ input, value, emptyRepo, canPushCode, canPushToBranch, exist }) => {
        createComponent({
          emptyRepo,
          canPushCode,
          canPushToBranch,
        });

        const inputMethod = findForm().find(`input[name="${input}"]`);

        if (!exist) {
          expect(inputMethod.exists()).toBe(false);
          return;
        }

        expect(inputMethod.attributes('type')).toBe('hidden');
        expect(inputMethod.attributes('value')).toBe(value);
      },
    );
  });

  describe('hint', () => {
    const targetText = 'some target branch';
    const hintText = 'Try to keep the first line under 52 characters and the others under 72.';
    const charsGenerator = (length) => 'lorem'.repeat(length);

    beforeEach(async () => {
      createFullComponent();
      await nextTick();
    });

    it.each`
      commitText                        | exist    | desc
      ${charsGenerator(53)}             | ${true}  | ${'first line length > 52'}
      ${`lorem\n${charsGenerator(73)}`} | ${true}  | ${'other line length > 72'}
      ${charsGenerator(52)}             | ${true}  | ${'other line length = 52'}
      ${`lorem\n${charsGenerator(72)}`} | ${true}  | ${'other line length = 72'}
      ${`lorem`}                        | ${false} | ${'first line length < 53'}
      ${`lorem\nlorem`}                 | ${false} | ${'other line length < 53'}
    `('displays hint $exist for $desc', async ({ commitText, exist }) => {
      await fillForm({ targetText, commitText });

      if (!exist) {
        expect(findCommitHint().exists()).toBe(false);
        return;
      }

      expect(findCommitHint().text()).toBe(hintText);
    });
  });

  describe('form submission', () => {
    let submitSpy;

    beforeEach(async () => {
      createFullComponent();
      await nextTick();
      submitSpy = jest.spyOn(findForm().element, 'submit');
    });

    afterEach(() => {
      submitSpy.mockRestore();
    });

    describe('invalid form', () => {
      beforeEach(async () => {
        await fillForm({ targetText: '', commitText: '' });
      });

      it('disables submit button', async () => {
        expect(findModal().props('actionPrimary').attributes[0]).toEqual(
          expect.objectContaining({ disabled: true }),
        );
      });

      it('does not submit form', async () => {
        findModal().vm.$emit('primary', { preventDefault: () => {} });
        expect(submitSpy).not.toHaveBeenCalled();
      });
    });

    describe('valid form', () => {
      beforeEach(async () => {
        await fillForm({
          targetText: 'some valid target branch',
          commitText: 'some valid commit message',
        });
      });

      it('enables submit button', async () => {
        expect(findModal().props('actionPrimary').attributes[0]).toEqual(
          expect.objectContaining({ disabled: false }),
        );
      });

      it('submits form', async () => {
        findModal().vm.$emit('primary', { preventDefault: () => {} });
        expect(submitSpy).toHaveBeenCalled();
      });
    });
  });
});
