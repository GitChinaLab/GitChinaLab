import Vue from 'vue';
import ExtensionBase from './base.vue';

// Holds all the currently registered extensions
export const registeredExtensions = Vue.observable({ extensions: [] });

export const registerExtension = (extension) => {
  // Pushes into the extenions array a dynamically created Vue component
  // that gets exteneded from `base.vue`
  registeredExtensions.extensions.push({
    extends: ExtensionBase,
    name: extension.name,
    props: extension.props,
    i18n: extension.i18n,
    expandEvent: extension.expandEvent,
    computed: {
      ...Object.keys(extension.computed).reduce(
        (acc, computedKey) => ({
          ...acc,
          // Making the computed property a method allows us to pass in arguments
          // this allows for each computed property to recieve some data
          [computedKey]() {
            return extension.computed[computedKey];
          },
        }),
        {},
      ),
    },
    methods: {
      ...extension.methods,
    },
  });
};
