import $ from 'jquery';

export const addTooltipToEl = (el) => {
  const textEl = el.querySelector('.js-breadcrumb-item-text');

  if (textEl && textEl.scrollWidth > textEl.offsetWidth) {
    el.setAttribute('title', el.textContent);
    el.setAttribute('data-container', 'body');
    el.classList.add('has-tooltip');
  }
};

export default () => {
  const breadcrumbs = document.querySelector('.js-breadcrumbs-list');

  if (breadcrumbs) {
    const topLevelLinks = [...breadcrumbs.children]
      .filter((el) => !el.classList.contains('dropdown'))
      .map((el) => el.querySelector('a'))
      .filter((el) => el);
    const $expanderBtn = $('.js-breadcrumbs-collapsed-expander');

    topLevelLinks.forEach((el) => addTooltipToEl(el));

    $expanderBtn.on('click', () => {
      const detailItems = $('.breadcrumbs-detail-item');
      const hiddenClass = 'gl-display-none!';

      $.each(detailItems, (_key, item) => {
        $(item).toggleClass(hiddenClass);
      });

      // remove the ellipsis
      $('li.expander').remove();

      // set focus on first breadcrumb item
      $('.breadcrumb-item-text').first().focus();
    });
  }
};
