import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { initIssuableApp } from '~/issues/show/issue';
import * as parseData from '~/issues/show/utils/parse_data';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/notes/stores';
import { appProps } from './mock_data/mock_data';

const mock = new MockAdapter(axios);
mock.onGet().reply(200);

jest.mock('~/lib/utils/poll');

const setupHTML = (initialData) => {
  document.body.innerHTML = `<div id="js-issuable-app"></div>`;
  document.getElementById('js-issuable-app').dataset.initial = JSON.stringify(initialData);
};

describe('Issue show index', () => {
  describe('initIssuableApp', () => {
    it('should initialize app with no potential XSS attack', async () => {
      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {});
      const parseDataSpy = jest.spyOn(parseData, 'parseIssuableData');

      setupHTML({
        ...appProps,
        initialDescriptionHtml: '<svg onload=window.alert(1)>',
      });

      const initialDataEl = document.getElementById('js-issuable-app');
      const issuableData = parseData.parseIssuableData(initialDataEl);
      initIssuableApp(issuableData, createStore());

      await waitForPromises();

      expect(parseDataSpy).toHaveBeenCalled();
      expect(alertSpy).not.toHaveBeenCalled();
    });
  });
});
