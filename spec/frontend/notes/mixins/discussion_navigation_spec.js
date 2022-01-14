import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import { setHTMLFixture } from 'helpers/fixtures';
import createEventHub from '~/helpers/event_hub_factory';
import * as utils from '~/lib/utils/common_utils';
import eventHub from '~/notes/event_hub';
import discussionNavigation from '~/notes/mixins/discussion_navigation';
import notesModule from '~/notes/stores/modules';

let scrollToFile;
const discussion = (id, index) => ({
  id,
  resolvable: index % 2 === 0,
  active: true,
  notes: [{}],
  diff_discussion: true,
  position: { new_line: 1, old_line: 1 },
  diff_file: { file_path: 'test.js' },
});
const createDiscussions = () => [...'abcde'].map(discussion);
const createComponent = () => ({
  mixins: [discussionNavigation],
  render() {
    return this.$slots.default;
  },
});

describe('Discussion navigation mixin', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;
  let store;
  let expandDiscussion;

  beforeEach(() => {
    setHTMLFixture(
      [...'abcde']
        .map(
          (id) =>
            `<ul class="notes" data-discussion-id="${id}"></ul>
            <div class="discussion" data-discussion-id="${id}"></div>`,
        )
        .join(''),
    );

    jest.spyOn(utils, 'scrollToElementWithContext');
    jest.spyOn(utils, 'scrollToElement');

    expandDiscussion = jest.fn();
    scrollToFile = jest.fn();
    const { actions, ...notesRest } = notesModule();
    store = new Vuex.Store({
      modules: {
        notes: {
          ...notesRest,
          actions: { ...actions, expandDiscussion },
        },
        diffs: {
          namespaced: true,
          actions: { scrollToFile },
        },
      },
    });
    store.state.notes.discussions = createDiscussions();

    wrapper = shallowMount(createComponent(), { store, localVue });
  });

  afterEach(() => {
    wrapper.vm.$destroy();
    jest.clearAllMocks();
  });

  const findDiscussion = (selector, id) =>
    document.querySelector(`${selector}[data-discussion-id="${id}"]`);

  describe('jumpToFirstUnresolvedDiscussion method', () => {
    let vm;

    beforeEach(() => {
      createComponent();

      ({ vm } = wrapper);

      jest.spyOn(store, 'dispatch');
      jest.spyOn(vm, 'jumpToNextDiscussion');
    });

    it('triggers the setCurrentDiscussionId action with null as the value', () => {
      vm.jumpToFirstUnresolvedDiscussion();

      expect(store.dispatch).toHaveBeenCalledWith('setCurrentDiscussionId', null);
    });

    it('triggers the jumpToNextDiscussion action when the previous store action succeeds', () => {
      store.dispatch.mockResolvedValue();

      vm.jumpToFirstUnresolvedDiscussion();

      return vm.$nextTick().then(() => {
        expect(vm.jumpToNextDiscussion).toHaveBeenCalled();
      });
    });
  });

  describe('cycle through discussions', () => {
    beforeEach(() => {
      window.mrTabs = { eventHub: createEventHub(), tabShown: jest.fn() };
    });

    describe.each`
      fn                                | args      | currentId | expected
      ${'jumpToNextDiscussion'}         | ${[]}     | ${null}   | ${'a'}
      ${'jumpToNextDiscussion'}         | ${[]}     | ${'a'}    | ${'c'}
      ${'jumpToNextDiscussion'}         | ${[]}     | ${'e'}    | ${'a'}
      ${'jumpToPreviousDiscussion'}     | ${[]}     | ${null}   | ${'e'}
      ${'jumpToPreviousDiscussion'}     | ${[]}     | ${'e'}    | ${'c'}
      ${'jumpToPreviousDiscussion'}     | ${[]}     | ${'c'}    | ${'a'}
      ${'jumpToNextRelativeDiscussion'} | ${[null]} | ${null}   | ${'a'}
      ${'jumpToNextRelativeDiscussion'} | ${['a']}  | ${null}   | ${'c'}
      ${'jumpToNextRelativeDiscussion'} | ${['e']}  | ${'c'}    | ${'a'}
    `('$fn (args = $args, currentId = $currentId)', ({ fn, args, currentId, expected }) => {
      beforeEach(() => {
        store.state.notes.currentDiscussionId = currentId;
      });

      describe('on `show` active tab', () => {
        beforeEach(() => {
          window.mrTabs.currentAction = 'show';
          wrapper.vm[fn](...args);

          return wrapper.vm.$nextTick();
        });

        it('sets current discussion', () => {
          expect(store.state.notes.currentDiscussionId).toEqual(expected);
        });

        it('expands discussion', () => {
          expect(expandDiscussion).toHaveBeenCalled();
        });

        it('scrolls to element', () => {
          expect(utils.scrollToElement).toHaveBeenCalledWith(
            findDiscussion('div.discussion', expected),
            { behavior: 'smooth' },
          );
        });
      });

      describe('on `diffs` active tab', () => {
        beforeEach(() => {
          window.mrTabs.currentAction = 'diffs';
          wrapper.vm[fn](...args);

          return wrapper.vm.$nextTick();
        });

        it('sets current discussion', () => {
          expect(store.state.notes.currentDiscussionId).toEqual(expected);
        });

        it('expands discussion', () => {
          expect(expandDiscussion).toHaveBeenCalled();
        });

        it('scrolls when scrollToDiscussion is emitted', () => {
          expect(utils.scrollToElementWithContext).not.toHaveBeenCalled();

          eventHub.$emit('scrollToDiscussion');

          expect(utils.scrollToElementWithContext).toHaveBeenCalledWith(
            findDiscussion('ul.notes', expected),
            { behavior: 'smooth' },
          );
        });
      });

      describe('on `other` active tab', () => {
        beforeEach(() => {
          window.mrTabs.currentAction = 'other';
          wrapper.vm[fn](...args);

          return wrapper.vm.$nextTick();
        });

        it('sets current discussion', () => {
          expect(store.state.notes.currentDiscussionId).toEqual(expected);
        });

        it('does not expand discussion yet', () => {
          expect(expandDiscussion).not.toHaveBeenCalled();
        });

        it('shows mrTabs', () => {
          expect(window.mrTabs.tabShown).toHaveBeenCalledWith('show');
        });

        describe('when tab is changed', () => {
          beforeEach(() => {
            window.mrTabs.eventHub.$emit('MergeRequestTabChange');

            jest.runAllTimers();
          });

          it('expands discussion', () => {
            expect(expandDiscussion).toHaveBeenCalledWith(expect.anything(), {
              discussionId: expected,
            });
          });

          it('scrolls to discussion', () => {
            expect(utils.scrollToElement).toHaveBeenCalledWith(
              findDiscussion('div.discussion', expected),
              { behavior: 'smooth' },
            );
          });
        });
      });
    });

    describe.each`
      diffsVirtualScrolling
      ${false}
      ${true}
    `('virtual scrolling feature is $diffsVirtualScrolling', ({ diffsVirtualScrolling }) => {
      beforeEach(() => {
        window.gon = { features: { diffsVirtualScrolling } };

        jest.spyOn(store, 'dispatch');

        store.state.notes.currentDiscussionId = 'a';
        window.location.hash = 'test';
      });

      afterEach(() => {
        window.gon = {};
        window.location.hash = '';
      });

      it('resets location hash if diffsVirtualScrolling flag is true', async () => {
        wrapper.vm.jumpToNextDiscussion();

        await nextTick();

        expect(window.location.hash).toBe(diffsVirtualScrolling ? '' : '#test');
      });

      it.each`
        tabValue   | hashValue
        ${'diffs'} | ${false}
        ${'show'}  | ${!diffsVirtualScrolling}
        ${'other'} | ${!diffsVirtualScrolling}
      `(
        'calls scrollToFile with setHash as $hashValue when the tab is $tabValue',
        async ({ hashValue, tabValue }) => {
          window.mrTabs.currentAction = tabValue;

          wrapper.vm.jumpToNextDiscussion();

          await nextTick();

          expect(store.dispatch).toHaveBeenCalledWith('diffs/scrollToFile', {
            path: 'test.js',
            setHash: hashValue,
          });
        },
      );
    });
  });
});
