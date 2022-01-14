import { GlCollapse } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { assets } from 'test_fixtures/api/releases/release.json';
import { trimText } from 'helpers/text_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ReleaseBlockAssets from '~/releases/components/release_block_assets.vue';
import { ASSET_LINK_TYPE } from '~/releases/constants';

describe('Release block assets', () => {
  let wrapper;
  let defaultProps;

  // A map of types to the expected section heading text
  const sections = {
    [ASSET_LINK_TYPE.IMAGE]: 'Images',
    [ASSET_LINK_TYPE.PACKAGE]: 'Packages',
    [ASSET_LINK_TYPE.RUNBOOK]: 'Runbooks',
    [ASSET_LINK_TYPE.OTHER]: 'Other',
  };

  const createComponent = (propsData = defaultProps) => {
    wrapper = mount(ReleaseBlockAssets, {
      propsData,
    });
  };

  const findSectionHeading = (type) =>
    wrapper.findAll('h5').filter((h5) => h5.text() === sections[type]);

  beforeEach(() => {
    defaultProps = { assets: convertObjectPropsToCamelCase(assets, { deep: true }) };
  });

  describe('with default props', () => {
    beforeEach(() => createComponent());

    const findAccordionButton = () => wrapper.find('[data-testid="accordion-button"]');

    it('renders an "Assets" accordion with the asset count', () => {
      const accordionButton = findAccordionButton();

      expect(accordionButton.exists()).toBe(true);
      expect(trimText(accordionButton.text())).toBe('Assets 8');
    });

    it('renders the accordion as expanded by default', () => {
      const accordion = wrapper.find(GlCollapse);

      expect(accordion.exists()).toBe(true);
      expect(accordion.isVisible()).toBe(true);
    });

    it('renders sources with the expected text and URL', () => {
      defaultProps.assets.sources.forEach((s) => {
        const sourceLink = wrapper.find(`li>a[href="${s.url}"]`);

        expect(sourceLink.exists()).toBe(true);
        expect(sourceLink.text()).toBe(`Source code (${s.format})`);
      });
    });

    it('renders a heading for each assets type (except sources)', () => {
      Object.keys(sections).forEach((type) => {
        const sectionHeadings = findSectionHeading(type);

        expect(sectionHeadings).toHaveLength(1);
      });
    });

    it('renders asset links with the expected text and URL', () => {
      defaultProps.assets.links.forEach((l) => {
        const sourceLink = wrapper.find(`li>a[href="${l.directAssetUrl}"]`);

        expect(sourceLink.exists()).toBe(true);
        expect(sourceLink.text()).toBe(l.name);
      });
    });
  });

  describe("when a release doesn't have a link with a certain asset type", () => {
    const typeToExclude = ASSET_LINK_TYPE.IMAGE;

    beforeEach(() => {
      defaultProps.assets.links = defaultProps.assets.links.filter(
        (l) => l.linkType !== typeToExclude,
      );
      createComponent(defaultProps);
    });

    it('does not render a section heading if there are no links of that type', () => {
      const sectionHeadings = findSectionHeading(typeToExclude);

      expect(sectionHeadings).toHaveLength(0);
    });
  });

  describe('sources', () => {
    const testSources = ({ shouldSourcesBeRendered }) => {
      assets.sources.forEach((s) => {
        expect(wrapper.find(`a[href="${s.url}"]`).exists()).toBe(shouldSourcesBeRendered);
      });
    };

    describe('when the release has sources', () => {
      beforeEach(() => {
        createComponent(defaultProps);
      });

      it('renders sources', () => {
        testSources({ shouldSourcesBeRendered: true });
      });
    });

    describe('when the release does not have sources', () => {
      beforeEach(() => {
        delete defaultProps.assets.sources;
        createComponent(defaultProps);
      });

      it('does not render any sources', () => {
        testSources({ shouldSourcesBeRendered: false });
      });
    });
  });

  describe('external vs internal links', () => {
    const containsExternalSourceIndicator = () =>
      wrapper.find('[data-testid="external-link-indicator"]').exists();

    describe('when a link is external', () => {
      beforeEach(() => {
        defaultProps.assets.sources = [];
        defaultProps.assets.links = [
          {
            ...defaultProps.assets.links[0],
            external: true,
          },
        ];
        createComponent(defaultProps);
      });

      it('renders the link with an "external source" indicator', () => {
        expect(containsExternalSourceIndicator()).toBe(true);
      });
    });

    describe('when a link is internal', () => {
      beforeEach(() => {
        defaultProps.assets.sources = [];
        defaultProps.assets.links = [
          {
            ...defaultProps.assets.links[0],
            external: false,
          },
        ];
        createComponent(defaultProps);
      });

      it('renders the link without the "external source" indicator', () => {
        expect(containsExternalSourceIndicator()).toBe(false);
      });
    });
  });
});
