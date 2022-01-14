import { shallowMount } from '@vue/test-utils';
import IssueToken from '~/related_issues/components/issue_token.vue';
import { PathIdSeparator } from '~/related_issues/constants';

describe('IssueToken', () => {
  const idKey = 200;
  const displayReference = 'foo/bar#123';
  const eventNamespace = 'pendingIssuable';
  const path = '/foo/bar/issues/123';
  const pathIdSeparator = PathIdSeparator.Issue;
  const title = 'some title';

  let wrapper;

  const defaultProps = {
    idKey,
    displayReference,
    pathIdSeparator,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IssueToken, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findLink = () => wrapper.find({ ref: 'link' });
  const findReference = () => wrapper.find({ ref: 'reference' });
  const findReferenceIcon = () => wrapper.find('[data-testid="referenceIcon"]');
  const findRemoveBtn = () => wrapper.find('[data-testid="removeBtn"]');
  const findTitle = () => wrapper.find({ ref: 'title' });

  describe('with reference supplied', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows reference', () => {
      expect(wrapper.text()).toContain(displayReference);
    });

    it('does not link without path specified', () => {
      expect(findLink().element.tagName).toBe('SPAN');
      expect(findLink().attributes('href')).toBeUndefined();
    });
  });

  describe('with reference and title supplied', () => {
    it('shows reference and title', () => {
      createComponent({
        title,
      });

      expect(findReference().text()).toBe(displayReference);
      expect(findTitle().text()).toBe(title);
    });
  });

  describe('with path and title supplied', () => {
    it('links reference and title', () => {
      createComponent({
        path,
        title,
      });

      expect(findLink().attributes('href')).toBe(path);
    });
  });

  describe('with state supplied', () => {
    it.each`
      state         | icon              | cssClass
      ${'opened'}   | ${'issue-open-m'} | ${'issue-token-state-icon-open'}
      ${'reopened'} | ${'issue-open-m'} | ${'issue-token-state-icon-open'}
      ${'closed'}   | ${'issue-close'}  | ${'issue-token-state-icon-closed'}
    `('shows "$icon" icon when "$state"', ({ state, icon, cssClass }) => {
      createComponent({
        path,
        state,
      });

      expect(findReferenceIcon().props('name')).toBe(icon);
      expect(findReferenceIcon().classes()).toContain(cssClass);
    });
  });

  describe('with reference, title, state', () => {
    const state = 'opened';

    it('shows reference, title, and state', () => {
      createComponent({
        title,
        state,
      });

      expect(findReferenceIcon().props('ariaLabel')).toBe(state);
      expect(findReference().text()).toBe(displayReference);
      expect(findTitle().text()).toBe(title);
    });
  });

  describe('with canRemove', () => {
    describe('`canRemove: false` (default)', () => {
      it('does not have remove button', () => {
        createComponent();

        expect(findRemoveBtn().exists()).toBe(false);
      });
    });

    describe('`canRemove: true`', () => {
      beforeEach(() => {
        createComponent({
          eventNamespace,
          canRemove: true,
        });
      });

      it('has remove button', () => {
        expect(findRemoveBtn().exists()).toBe(true);
      });

      it('emits event when clicked', () => {
        findRemoveBtn().trigger('click');

        const emitted = wrapper.emitted(`${eventNamespace}RemoveRequest`);

        expect(emitted).toHaveLength(1);
        expect(emitted[0]).toEqual([idKey]);
      });

      it('tooltip should not be escaped', () => {
        expect(findRemoveBtn().attributes('aria-label')).toBe(`Remove ${displayReference}`);
      });
    });
  });
});
