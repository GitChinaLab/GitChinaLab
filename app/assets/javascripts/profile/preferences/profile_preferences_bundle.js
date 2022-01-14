import Vue from 'vue';
import ProfilePreferences from './components/profile_preferences.vue';

export default () => {
  const el = document.querySelector('#js-profile-preferences-app');
  const formEl = document.querySelector('#profile-preferences-form');
  const shouldParse = ['integrationViews', 'themes', 'userFields'];

  const provide = Object.keys(el.dataset).reduce(
    (memo, key) => {
      let value = el.dataset[key];
      if (shouldParse.includes(key)) {
        value = JSON.parse(value);
      }

      return { ...memo, [key]: value };
    },
    { formEl },
  );

  return new Vue({
    el,
    name: 'ProfilePreferencesApp',
    provide,
    render: (createElement) => createElement(ProfilePreferences),
  });
};
