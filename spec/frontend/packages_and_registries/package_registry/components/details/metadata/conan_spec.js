import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  conanMetadata,
  packageData,
} from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/metadata/conan.vue';
import { PACKAGE_TYPE_CONAN } from '~/packages_and_registries/package_registry/constants';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

const conanPackage = { packageType: PACKAGE_TYPE_CONAN, metadata: conanMetadata() };

describe('Conan Metadata', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(component, {
      propsData: {
        packageEntity: packageData(conanPackage),
      },
      stubs: {
        DetailsRow,
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findConanRecipe = () => wrapper.findByTestId('conan-recipe');

  beforeEach(() => {
    mountComponent();
  });

  it.each`
    name        | finderFunction     | text                                                       | icon
    ${'recipe'} | ${findConanRecipe} | ${'Recipe: package-8/1.0.0@gitlab-org+gitlab-test/stable'} | ${'information-o'}
  `('$name element', ({ finderFunction, text, icon }) => {
    const element = finderFunction();
    expect(element.exists()).toBe(true);
    expect(element.text()).toBe(text);
    expect(element.props('icon')).toBe(icon);
  });
});
