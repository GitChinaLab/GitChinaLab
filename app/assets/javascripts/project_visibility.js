import $ from 'jquery';
import eventHub from '~/projects/new/event_hub';

// Values are from lib/gitlab/visibility_level.rb
const visibilityLevel = {
  private: 0,
  internal: 10,
  public: 20,
};

function setVisibilityOptions({ name, visibility, showPath, editPath }) {
  document.querySelectorAll('.visibility-level-setting .form-check').forEach((option) => {
    // Don't change anything if the option is restricted by admin
    if (option.classList.contains('restricted')) {
      return;
    }

    const optionInput = option.querySelector('input[type=radio]');
    const optionValue = optionInput ? parseInt(optionInput.value, 10) : 0;

    if (visibilityLevel[visibility] < optionValue) {
      option.classList.add('disabled');
      optionInput.disabled = true;
      const reason = option.querySelector('.option-disabled-reason');
      if (reason) {
        const optionTitle = option.querySelector('.option-title');
        const optionName = optionTitle ? optionTitle.innerText.toLowerCase() : '';
        reason.innerHTML = `This project cannot be ${optionName} because the visibility of
            <a href="${showPath}">${name}</a> is ${visibility}. To make this project
            ${optionName}, you must first <a href="${editPath}">change the visibility</a>
            of the parent group.`;
      }
    } else {
      option.classList.remove('disabled');
      optionInput.disabled = false;
    }
  });
}

function handleSelect2DropdownChange(namespaceSelector) {
  if (!namespaceSelector || !('selectedIndex' in namespaceSelector)) {
    return;
  }
  const selectedNamespace = namespaceSelector.options[namespaceSelector.selectedIndex];
  setVisibilityOptions(selectedNamespace.dataset);
}

export default function initProjectVisibilitySelector() {
  eventHub.$on('update-visibility', setVisibilityOptions);

  const namespaceSelector = document.querySelector('select.js-select-namespace');
  if (namespaceSelector) {
    $('.select2.js-select-namespace').on('change', () =>
      handleSelect2DropdownChange(namespaceSelector),
    );
    handleSelect2DropdownChange(namespaceSelector);
  }
}
