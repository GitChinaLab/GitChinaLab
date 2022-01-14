import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const createStore = (entryPointData = {}) =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state: createState(entryPointData),
  });

export default createStore;
