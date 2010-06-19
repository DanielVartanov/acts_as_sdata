module SData
  class Formatting
    def self.format_date_time(date_time)
      return date_time unless date_time
      case date_time.class.name
      when 'ActiveSupport::TimeWithZone', 'Time'
        date_time.strftime("%Y-%m-%dT%H:%M:%S%z").insert(-3,':')
      when 'Date'
        date_time.strftime("%Y-%m-%d")
      end
    end
  end
end