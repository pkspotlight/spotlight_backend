def initialize_parse
  Parse.create(application_id: ENV['parse_application_id'],
               api_key: ENV['parse_api_key'],
               master_key: ENV['parse_master_key'],
               path: '/parse',
               host: ENV['parse_host'])
end

$parse ||= initialize_parse
