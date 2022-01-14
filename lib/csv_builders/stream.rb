# frozen_string_literal: true

module CsvBuilders
  class Stream < CsvBuilder
    def render(max_rows = 100_000)
      max_rows_including_header = max_rows + 1

      Enumerator.new do |csv|
        csv << CSV.generate_line(headers)

        each do |object|
          csv << CSV.generate_line(row(object))
        end
      end.lazy.take(max_rows_including_header) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
