export const mockRegularLabel = {
  id: 26,
  title: 'Foo Label',
  description: 'Foobar',
  color: '#BADA55',
  textColor: '#FFFFFF',
};

export const mockScopedLabel = {
  id: 27,
  title: 'Foo::Bar',
  description: 'Foobar',
  color: '#0033CC',
  textColor: '#FFFFFF',
};

export const mockLabels = [
  {
    id: 29,
    title: 'Boog',
    description: 'Label for bugs',
    color: '#FF0000',
    textColor: '#FFFFFF',
  },
  {
    id: 28,
    title: 'Bug',
    description: 'Label for bugs',
    color: '#FF0000',
    textColor: '#FFFFFF',
  },
  mockRegularLabel,
  mockScopedLabel,
];

export const mockCollapsedLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
  {
    id: 27,
    title: 'Foo::Bar',
    description: 'Foobar',
    color: '#0033CC',
    text_color: '#FFFFFF',
  },
];

export const mockConfig = {
  allowLabelEdit: true,
  allowLabelCreate: true,
  allowScopedLabels: true,
  allowMultiselect: true,
  labelsListTitle: 'Assign labels',
  labelsCreateTitle: 'Create label',
  variant: 'sidebar',
  dropdownOnly: false,
  selectedLabels: [mockRegularLabel, mockScopedLabel],
  labelsSelectInProgress: false,
  labelsFetchPath: '/gitlab-org/my-project/-/labels.json',
  labelsManagePath: '/gitlab-org/my-project/-/labels',
  labelsFilterBasePath: '/gitlab-org/my-project/issues',
  labelsFilterParam: 'label_name',
};

export const mockSuggestedColors = {
  '#009966': 'Green-cyan',
  '#8fbc8f': 'Dark sea green',
  '#3cb371': 'Medium sea green',
  '#00b140': 'Green screen',
  '#013220': 'Dark green',
  '#6699cc': 'Blue-gray',
  '#0000ff': 'Blue',
  '#e6e6fa': 'Lavender',
  '#9400d3': 'Dark violet',
  '#330066': 'Deep violet',
  '#808080': 'Gray',
  '#36454f': 'Charcoal grey',
  '#f7e7ce': 'Champagne',
  '#c21e56': 'Rose red',
  '#cc338b': 'Magenta-pink',
  '#dc143c': 'Crimson',
  '#ff0000': 'Red',
  '#cd5b45': 'Dark coral',
  '#eee600': 'Titanium yellow',
  '#ed9121': 'Carrot orange',
  '#c39953': 'Aztec Gold',
};
