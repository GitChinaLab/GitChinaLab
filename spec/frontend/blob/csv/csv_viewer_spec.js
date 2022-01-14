import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { getAllByRole } from '@testing-library/dom';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CsvViewer from '~/blob/csv/csv_viewer.vue';
import PapaParseAlert from '~/vue_shared/components/papa_parse_alert.vue';

const validCsv = 'one,two,three';
const brokenCsv = '{\n "json": 1,\n "key": [1, 2, 3]\n}';

describe('app/assets/javascripts/blob/csv/csv_viewer.vue', () => {
  let wrapper;

  const createComponent = ({ csv = validCsv, mountFunction = shallowMount } = {}) => {
    wrapper = mountFunction(CsvViewer, {
      propsData: {
        csv,
      },
    });
  };

  const findCsvTable = () => wrapper.findComponent(GlTable);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(PapaParseAlert);

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render loading spinner', () => {
    createComponent();

    expect(findLoadingIcon().props()).toMatchObject({
      size: 'lg',
    });
  });

  describe('when the CSV contains errors', () => {
    it('should render alert with correct props', async () => {
      createComponent({ csv: brokenCsv });
      await nextTick;

      expect(findAlert().props()).toMatchObject({
        papaParseErrors: [{ code: 'UndetectableDelimiter' }],
      });
    });
  });

  describe('when the CSV contains no errors', () => {
    it('should not render alert', async () => {
      createComponent();
      await nextTick;

      expect(findAlert().exists()).toBe(false);
    });

    it('renders the CSV table with the correct attributes', async () => {
      createComponent();
      await nextTick;

      expect(findCsvTable().attributes()).toMatchObject({
        'empty-text': 'No CSV data to display.',
        items: validCsv,
      });
    });

    it('renders the CSV table with the correct content', async () => {
      createComponent({ mountFunction: mount });
      await nextTick;

      expect(getAllByRole(wrapper.element, 'row', { name: /One/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /Two/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /Three/i })).toHaveLength(1);
    });
  });
});
