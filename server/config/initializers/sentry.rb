Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    # setup the enviroment
    config.enviroment = ENV['RAILS_ENV']
    config.breadcrumbs_logger = [:monotonic_active_support_logger, :http_logger]

    config.traces_sampler = lambda do |sampling_context|
        
        transaction_context = sampling_context[:transaction_context]
        op = transaction_context[:op]
        transaction_name = transaction_context[:name]

        case op
        when /request/
            case transaction_name
            when /health_check/
                0.0
            else
                0.1
            end
        end
    end
end