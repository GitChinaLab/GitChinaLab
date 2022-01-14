import { ApolloLink, Observable } from 'apollo-link';
import waitForPromises from 'helpers/wait_for_promises';
import { getSuppressNetworkErrorsDuringNavigationLink } from '~/lib/apollo/suppress_network_errors_during_navigation_link';
import { isNavigatingAway } from '~/lib/utils/is_navigating_away';

jest.mock('~/lib/utils/is_navigating_away');

describe('getSuppressNetworkErrorsDuringNavigationLink', () => {
  const originalGon = window.gon;
  let subscription;

  beforeEach(() => {
    window.gon = originalGon;
  });

  afterEach(() => {
    if (subscription) {
      subscription.unsubscribe();
    }
  });

  const makeMockGraphQLErrorLink = () =>
    new ApolloLink(() =>
      Observable.of({
        errors: [
          {
            message: 'foo',
          },
        ],
      }),
    );

  const makeMockNetworkErrorLink = () =>
    new ApolloLink(
      () =>
        new Observable(() => {
          throw new Error('NetworkError');
        }),
    );

  const makeMockSuccessLink = () =>
    new ApolloLink(() => Observable.of({ data: { foo: { id: 1 } } }));

  const createSubscription = (otherLink, observer) => {
    const mockOperation = { operationName: 'foo' };
    const link = getSuppressNetworkErrorsDuringNavigationLink().concat(otherLink);
    subscription = link.request(mockOperation).subscribe(observer);
  };

  it('returns an ApolloLink', () => {
    expect(getSuppressNetworkErrorsDuringNavigationLink()).toEqual(expect.any(ApolloLink));
  });

  describe('suppression case', () => {
    describe('when navigating away', () => {
      beforeEach(() => {
        isNavigatingAway.mockReturnValue(true);
      });

      describe('given a network error', () => {
        it('does not forward the error', async () => {
          const spy = jest.fn();

          createSubscription(makeMockNetworkErrorLink(), {
            next: spy,
            error: spy,
            complete: spy,
          });

          // It's hard to test for something _not_ happening. The best we can
          // do is wait a bit to make sure nothing happens.
          await waitForPromises();
          expect(spy).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('non-suppression cases', () => {
    describe('when not navigating away', () => {
      beforeEach(() => {
        isNavigatingAway.mockReturnValue(false);
      });

      it('forwards successful requests', (done) => {
        createSubscription(makeMockSuccessLink(), {
          next({ data }) {
            expect(data).toEqual({ foo: { id: 1 } });
          },
          error: () => done.fail('Should not happen'),
          complete: () => done(),
        });
      });

      it('forwards GraphQL errors', (done) => {
        createSubscription(makeMockGraphQLErrorLink(), {
          next({ errors }) {
            expect(errors).toEqual([{ message: 'foo' }]);
          },
          error: () => done.fail('Should not happen'),
          complete: () => done(),
        });
      });

      it('forwards network errors', (done) => {
        createSubscription(makeMockNetworkErrorLink(), {
          next: () => done.fail('Should not happen'),
          error: (error) => {
            expect(error.message).toBe('NetworkError');
            done();
          },
          complete: () => done.fail('Should not happen'),
        });
      });
    });

    describe('when navigating away', () => {
      beforeEach(() => {
        isNavigatingAway.mockReturnValue(true);
      });

      it('forwards successful requests', (done) => {
        createSubscription(makeMockSuccessLink(), {
          next({ data }) {
            expect(data).toEqual({ foo: { id: 1 } });
          },
          error: () => done.fail('Should not happen'),
          complete: () => done(),
        });
      });

      it('forwards GraphQL errors', (done) => {
        createSubscription(makeMockGraphQLErrorLink(), {
          next({ errors }) {
            expect(errors).toEqual([{ message: 'foo' }]);
          },
          error: () => done.fail('Should not happen'),
          complete: () => done(),
        });
      });
    });
  });
});
