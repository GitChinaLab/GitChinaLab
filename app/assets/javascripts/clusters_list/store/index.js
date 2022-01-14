import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const createStore = (initialState) =>
  new Vuex.Store({
    actions,
    mutations,
    state: state(initialState),
  });

export default createStore;
