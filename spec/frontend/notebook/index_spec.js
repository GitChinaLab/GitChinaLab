import { mount } from '@vue/test-utils';
import Vue from 'vue';
import json from 'test_fixtures/blob/notebook/basic.json';
import jsonWithWorksheet from 'test_fixtures/blob/notebook/worksheets.json';
import Notebook from '~/notebook/index.vue';

const Component = Vue.extend(Notebook);

describe('Notebook component', () => {
  let vm;

  function buildComponent(notebook) {
    return mount(Component, {
      propsData: { notebook, codeCssClass: 'js-code-class' },
      provide: { relativeRawPath: '' },
    }).vm;
  }

  describe('without JSON', () => {
    beforeEach((done) => {
      vm = buildComponent({});

      setImmediate(() => {
        done();
      });
    });

    it('does not render', () => {
      expect(vm.$el.tagName).toBeUndefined();
    });
  });

  describe('with JSON', () => {
    beforeEach((done) => {
      vm = buildComponent(json);

      setImmediate(() => {
        done();
      });
    });

    it('renders cells', () => {
      expect(vm.$el.querySelectorAll('.cell').length).toBe(json.cells.length);
    });

    it('renders markdown cell', () => {
      expect(vm.$el.querySelector('.markdown')).not.toBeNull();
    });

    it('renders code cell', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
    });

    it('add code class to code blocks', () => {
      expect(vm.$el.querySelector('.js-code-class')).not.toBeNull();
    });
  });

  describe('with worksheets', () => {
    beforeEach((done) => {
      vm = buildComponent(jsonWithWorksheet);

      setImmediate(() => {
        done();
      });
    });

    it('renders cells', () => {
      expect(vm.$el.querySelectorAll('.cell').length).toBe(
        jsonWithWorksheet.worksheets[0].cells.length,
      );
    });

    it('renders markdown cell', () => {
      expect(vm.$el.querySelector('.markdown')).not.toBeNull();
    });

    it('renders code cell', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
    });

    it('add code class to code blocks', () => {
      expect(vm.$el.querySelector('.js-code-class')).not.toBeNull();
    });
  });
});
