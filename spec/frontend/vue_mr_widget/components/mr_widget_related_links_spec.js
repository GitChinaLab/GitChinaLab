import { shallowMount } from '@vue/test-utils';
import RelatedLinks from '~/vue_merge_request_widget/components/mr_widget_related_links.vue';

describe('MRWidgetRelatedLinks', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(RelatedLinks, { propsData });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('closesText', () => {
      it('returns Closes text for open merge request', () => {
        createComponent({ state: 'open', relatedLinks: {} });

        expect(wrapper.vm.closesText).toBe('Closes issues');
      });

      it('returns correct text for closed merge request', () => {
        createComponent({ state: 'closed', relatedLinks: {} });

        expect(wrapper.vm.closesText).toBe('Did not close');
      });

      it('returns correct tense for merged request', () => {
        createComponent({ state: 'merged', relatedLinks: {} });

        expect(wrapper.vm.closesText).toBe('Closed');
      });
    });
  });

  it('should have only have closing issues text', () => {
    createComponent({
      relatedLinks: {
        closing: '<a href="#">#23</a> and <a>#42</a>',
        closingCount: 2,
      },
    });
    const content = wrapper
      .text()
      .replace(/\n(\s)+/g, ' ')
      .trim();

    expect(content).toContain('Closes issues #23 and #42');
    expect(content).not.toContain('Mentions');
  });

  it('should have only have mentioned issues text', () => {
    createComponent({
      relatedLinks: {
        mentioned: '<a href="#">#7</a>',
        mentionedCount: 1,
      },
    });

    const content = wrapper
      .text()
      .replace(/\n(\s)+/g, ' ')
      .trim();

    expect(content).toContain('Mentions issue #7');
    expect(content).not.toContain('Closes issues');
  });

  it('should have closing and mentioned issues at the same time', () => {
    createComponent({
      relatedLinks: {
        closing: '<a href="#">#7</a>',
        mentioned: '<a href="#">#23</a> and <a>#42</a>',
        closingCount: 1,
        mentionedCount: 2,
      },
    });
    const content = wrapper
      .text()
      .replace(/\n(\s)+/g, ' ')
      .trim();

    expect(content).toContain('Closes issue #7');
    expect(content).toContain('Mentions issues #23 and #42');
  });

  it('should have assing issues link', () => {
    createComponent({
      relatedLinks: {
        assignToMe: '<a href="#">Assign yourself to these issues</a>',
      },
    });

    expect(wrapper.text().trim()).toContain('Assign yourself to these issues');
  });
});
