export const getIssueTimelogsQueryResponse = {
  data: {
    issuable: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/148',
      title:
        'Est perferendis dicta expedita ipsum adipisci laudantium omnis consequatur consequatur et.',
      timelogs: {
        nodes: [
          {
            __typename: 'Timelog',
            timeSpent: 14400,
            user: {
              id: 'user-1',
              name: 'John Doe18',
              __typename: 'UserCore',
            },
            spentAt: '2020-05-01T00:00:00Z',
            note: {
              id: 'note-1',
              body: 'A note',
              __typename: 'Note',
            },
            summary: 'A summary',
          },
          {
            __typename: 'Timelog',
            timeSpent: 1800,
            user: {
              id: 'user-2',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T13:19:01Z',
            note: null,
            summary: 'A summary',
          },
          {
            __typename: 'Timelog',
            timeSpent: 14400,
            user: {
              id: 'user-2',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-01T00:00:00Z',
            note: {
              id: 'note-2',
              body: 'A note',
              __typename: 'Note',
            },
            summary: null,
          },
        ],
        __typename: 'TimelogConnection',
      },
    },
  },
};

export const getMrTimelogsQueryResponse = {
  data: {
    issuable: {
      __typename: 'MergeRequest',
      id: 'gid://gitlab/MergeRequest/29',
      title: 'Esse amet perspiciatis voluptas et sed praesentium debitis repellat.',
      timelogs: {
        nodes: [
          {
            __typename: 'Timelog',
            timeSpent: 1800,
            user: {
              id: 'user-1',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T14:44:55Z',
            note: {
              id: 'note-1',
              body: 'Thirty minutes!',
              __typename: 'Note',
            },
            summary: null,
          },
          {
            __typename: 'Timelog',
            timeSpent: 3600,
            user: {
              id: 'user-1',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T14:44:39Z',
            note: null,
            summary: null,
          },
          {
            __typename: 'Timelog',
            timeSpent: 300,
            user: {
              id: 'user-1',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-03-10T00:00:00Z',
            note: {
              id: 'note-2',
              body: 'A note with some time',
              __typename: 'Note',
            },
            summary: null,
          },
        ],
        __typename: 'TimelogConnection',
      },
    },
  },
};
