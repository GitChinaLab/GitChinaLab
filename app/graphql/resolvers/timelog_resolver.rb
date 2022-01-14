# frozen_string_literal: true

module Resolvers
  class TimelogResolver < BaseResolver
    include LooksAhead
    include ResolvesIds

    type ::Types::TimelogType.connection_type, null: false

    argument :start_date, Types::TimeType,
             required: false,
             description: 'List timelogs within a date range where the logged date is equal to or after startDate.'

    argument :end_date, Types::TimeType,
             required: false,
             description: 'List timelogs within a date range where the logged date is equal to or before endDate.'

    argument :start_time, Types::TimeType,
             required: false,
             description: 'List timelogs within a time range where the logged time is equal to or after startTime.'

    argument :end_time, Types::TimeType,
             required: false,
             description: 'List timelogs within a time range where the logged time is equal to or before endTime.'

    argument :project_id, ::Types::GlobalIDType[::Project],
             required: false,
             description: 'List timelogs for a project.'

    argument :group_id, ::Types::GlobalIDType[::Group],
             required: false,
             description: 'List timelogs for a group.'

    argument :username, GraphQL::Types::String,
             required: false,
             description: 'List timelogs for a user.'

    def resolve_with_lookahead(**args)
      validate_args!(object, args)

      timelogs = object&.timelogs || Timelog.limit(GitlabSchema.default_max_page_size)

      if args.any?
        args = parse_datetime_args(args)

        timelogs = apply_user_filter(timelogs, args)
        timelogs = apply_project_filter(timelogs, args)
        timelogs = apply_time_filter(timelogs, args)
        timelogs = apply_group_filter(timelogs, args)
      end

      apply_lookahead(timelogs)
    end

    private

    def preloads
      {
        note: [:note]
      }
    end

    def validate_args!(object, args)
      if args.empty? && object.nil?
        raise_argument_error('Provide at least one argument')
      elsif args[:start_time] && args[:start_date]
        raise_argument_error('Provide either a start date or time, but not both')
      elsif args[:end_time] && args[:end_date]
        raise_argument_error('Provide either an end date or time, but not both')
      end
    end

    def parse_datetime_args(args)
      if times_provided?(args)
        args
      else
        parsed_args = args.except(:start_date, :end_date)

        parsed_args[:start_time] = args[:start_date].beginning_of_day if args[:start_date]
        parsed_args[:end_time] = args[:end_date].end_of_day if args[:end_date]

        parsed_args
      end
    end

    def times_provided?(args)
      args[:start_time] && args[:end_time]
    end

    def validate_time_difference!(args)
      return unless end_time_before_start_time?(args)

      raise_argument_error('Start argument must be before End argument')
    end

    def end_time_before_start_time?(args)
      times_provided?(args) && args[:end_time] < args[:start_time]
    end

    def apply_project_filter(timelogs, args)
      return timelogs unless args[:project_id]

      project = resolve_ids(args[:project_id], ::Types::GlobalIDType[::Project])
      timelogs.in_project(project)
    end

    def apply_group_filter(timelogs, args)
      return timelogs unless args[:group_id]

      group = Group.find_by_id(resolve_ids(args[:group_id], ::Types::GlobalIDType[::Group]))
      timelogs.in_group(group)
    end

    def apply_user_filter(timelogs, args)
      return timelogs unless args[:username]

      user = UserFinder.new(args[:username]).find_by_username!
      timelogs.for_user(user)
    end

    def apply_time_filter(timelogs, args)
      return timelogs unless args[:start_time] || args[:end_time]

      validate_time_difference!(args)

      if args[:start_time]
        timelogs = timelogs.at_or_after(args[:start_time])
      end

      if args[:end_time]
        timelogs = timelogs.at_or_before(args[:end_time])
      end

      timelogs
    end

    def raise_argument_error(message)
      raise Gitlab::Graphql::Errors::ArgumentError, message
    end
  end
end
