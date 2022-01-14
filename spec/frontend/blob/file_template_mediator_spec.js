import TemplateSelectorMediator from '~/blob/file_template_mediator';

describe('Template Selector Mediator', () => {
  let mediator;

  describe('setFilename', () => {
    let input;
    const newFileName = 'foo';
    const editor = jest.fn().mockImplementationOnce(() => ({
      getValue: jest.fn().mockImplementation(() => {}),
    }))();

    beforeEach(() => {
      setFixtures('<div class="file-editor"><input class="js-file-path-name-input" /></div>');
      input = document.querySelector('.js-file-path-name-input');
      mediator = new TemplateSelectorMediator({
        editor,
        currentAction: jest.fn(),
        projectId: jest.fn(),
      });
    });

    it('fills out the input field', () => {
      expect(input.value).toBe('');
      mediator.setFilename(newFileName);
      expect(input.value).toBe(newFileName);
    });

    it.each`
      name           | newName        | shouldDispatch
      ${newFileName} | ${newFileName} | ${false}
      ${newFileName} | ${''}          | ${true}
      ${newFileName} | ${undefined}   | ${false}
      ${''}          | ${''}          | ${false}
      ${''}          | ${newFileName} | ${true}
      ${''}          | ${undefined}   | ${false}
    `(
      'correctly reacts to the name change when current name is $name and newName is $newName',
      ({ name, newName, shouldDispatch }) => {
        input.value = name;
        const eventHandler = jest.fn();
        input.addEventListener('change', eventHandler);

        mediator.setFilename(newName);
        if (shouldDispatch) {
          expect(eventHandler).toHaveBeenCalledTimes(1);
        } else {
          expect(eventHandler).not.toHaveBeenCalled();
        }
      },
    );
  });
});
