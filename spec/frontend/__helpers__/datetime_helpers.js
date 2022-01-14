import dateFormat from 'dateformat';

/**
 * Returns a date object corresponding to the given date string.
 */
export const dateFromString = (dateString) => new Date(dateFormat(dateString));
