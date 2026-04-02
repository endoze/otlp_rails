module OTLPRails
  class Railtie < ::Rails::Railtie
    initializer "otlp_rails.subscribe",
      after: :load_config_initializers do
      OTLPRails.subscribe!
    end
  end
end
