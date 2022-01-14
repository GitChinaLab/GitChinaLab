import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/vuex_shared/modules/modal/actions';
import * as types from '~/vuex_shared/modules/modal/mutation_types';

describe('Vuex ModalModule actions', () => {
  describe('open', () => {
    it('works', (done) => {
      const data = { id: 7 };

      testAction(actions.open, data, {}, [{ type: types.OPEN, payload: data }], [], done);
    });
  });

  describe('close', () => {
    it('works', (done) => {
      testAction(actions.close, null, {}, [{ type: types.CLOSE }], [], done);
    });
  });

  describe('show', () => {
    it('works', (done) => {
      testAction(actions.show, null, {}, [{ type: types.SHOW }], [], done);
    });
  });

  describe('hide', () => {
    it('works', (done) => {
      testAction(actions.hide, null, {}, [{ type: types.HIDE }], [], done);
    });
  });
});
