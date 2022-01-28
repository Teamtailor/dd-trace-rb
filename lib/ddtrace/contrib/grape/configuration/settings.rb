# typed: false
require 'ddtrace/contrib/configuration/settings'
require 'ddtrace/contrib/grape/ext'
require 'ddtrace/contrib/status_code_matcher'

module Datadog
  module Contrib
    module Grape
      module Configuration
        # Custom settings for the Grape integration
        # @public_api
        class Settings < Contrib::Configuration::Settings
          option :enabled do |o|
            o.default { env_to_bool(Ext::ENV_ENABLED, true) }
            o.lazy
          end

          option :analytics_enabled do |o|
            o.default { env_to_bool(Ext::ENV_ANALYTICS_ENABLED, nil) }
            o.lazy
          end

          option :analytics_sample_rate do |o|
            o.default { env_to_float(Ext::ENV_ANALYTICS_SAMPLE_RATE, 1.0) }
            o.lazy
          end

          option :service_name

          option :error_statuses, default: nil do |o|
            o.setter do |new_value, _old_value|
              Contrib::StatusCodeMatcher.new(new_value) unless new_value.nil?
            end
          end
        end
      end
    end
  end
end
