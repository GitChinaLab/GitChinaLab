import Vue from 'vue';
import App from './components/app.vue';
import { createRouter } from './router';
import { createApolloProvider } from './graphql/provider';

export const initWorkItemsRoot = () => {
  const el = document.querySelector('#js-work-items');

  return new Vue({
    el,
    router: createRouter(el.dataset.fullPath),
    apolloProvider: createApolloProvider(),
    render(createElement) {
      return createElement(App);
    },
  });
};
