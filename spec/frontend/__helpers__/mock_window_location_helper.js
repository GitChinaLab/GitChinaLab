/**
 * Manage the instance of a custom `window.location`
 *
 * This only encapsulates the setup / teardown logic so that it can easily be
 * reused with different implementations (i.e. a spy or a fake)
 *
 * @param {() => any} fn Function that returns the object to use for window.location
 */
const useMockLocation = (fn) => {
  const origWindowLocation = window.location;
  let currentWindowLocation = origWindowLocation;

  Object.defineProperty(window, 'location', {
    get: () => currentWindowLocation,
  });

  beforeEach(() => {
    currentWindowLocation = fn();
  });

  afterEach(() => {
    currentWindowLocation = origWindowLocation;
  });
};

/**
 * Create an object with the location interface but `jest.fn()` implementations.
 */
export const createWindowLocationSpy = () => {
  return {
    assign: jest.fn(),
    reload: jest.fn(),
    replace: jest.fn(),
    toString: jest.fn(),
  };
};

/**
 * Before each test, overwrite `window.location` with a spy implementation.
 */
export const useMockLocationHelper = () => useMockLocation(createWindowLocationSpy);
