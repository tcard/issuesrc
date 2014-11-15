module Issuesrc
  module Config
    def self.report_missing_in_config(option)
      Issuesrc::exec_fail "Missing config entry: #{option}"
    end

    def self.option_from_both(option_args, option_config, args, config,
                              flags = {})
      value = option_from_args(option_args, args)
      if value.nil?
        value = option_from_config(option_config, config)
      end
      option_from_check_require(
        "#{option_args} or #{option_config.join('.')}", value, flags)
    end

    def self.option_from_args(option, args, flags = {})
      value = args.fetch(option, nil)
      option_from_check_require(option, value, flags)
    end

    def self.option_from_config(option, config, flags = {})
      value = config
      option.each do |part|
        if !value.include?(part)
          value = nil
          break
        end
        value = value[part]
      end
      option_from_check_require(option.join('.'), value, flags)
    end

    private
    def self.option_from_check_require(option, value, flags)
      if value.nil? && flags.include?(:require)
        report_missing_in_config option
      end
      value
    end
  end
end