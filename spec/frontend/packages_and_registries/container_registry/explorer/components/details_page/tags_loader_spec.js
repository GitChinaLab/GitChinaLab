import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_loader.vue';
import { GlSkeletonLoader } from '../../stubs';

describe('TagsLoader component', () => {
  let wrapper;

  const findGlSkeletonLoaders = () => wrapper.findAll(GlSkeletonLoader);

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      stubs: {
        GlSkeletonLoader,
      },
      // set the repeat to 1 to avoid a long and verbose snapshot
      loader: {
        ...component.loader,
        repeat: 1,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('produces the correct amount of loaders ', () => {
    mountComponent();
    expect(findGlSkeletonLoaders().length).toBe(1);
  });

  it('has the correct props', () => {
    mountComponent();
    expect(findGlSkeletonLoaders().at(0).props()).toMatchObject({
      width: component.loader.width,
      height: component.loader.height,
    });
  });

  it('has the correct markup', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });
});
