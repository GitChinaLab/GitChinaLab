/**
 * Returns a new object with keys pointing to stubbed methods
 *
 * This is helpful for stubbing components like GlModal where it's supported
 * in the API to call `.show()` and `.hide()` ([Bootstrap Vue docs][1]).
 *
 * [1]: https://bootstrap-vue.org/docs/components/modal#using-show-hide-and-toggle-component-methods
 *
 * @param {Object} methods - Object whose keys will be in the returned object.
 */
const createStubbedMethods = (methods = {}) => {
  if (!methods) {
    return {};
  }

  return Object.keys(methods).reduce(
    (acc, key) =>
      Object.assign(acc, {
        [key]: () => {},
      }),
    {},
  );
};

export function stubComponent(Component, options = {}) {
  return {
    props: Component.props,
    model: Component.model,
    methods: createStubbedMethods(Component.methods),
    // Do not render any slots/scoped slots except default
    // This differs from VTU behavior which renders all slots
    template: '<div><slot></slot></div>',
    // allows wrapper.find(Component) to work for stub
    $_vueTestUtils_original: Component,
    ...options,
  };
}
