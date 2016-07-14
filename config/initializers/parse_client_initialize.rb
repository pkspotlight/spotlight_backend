def initialize_parse
  Parse.create(application_id: ENV['parse_application_id'],
               api_key: ENV['parse_api_key'],
               master_key: ENV['parse_master_key'])
end

$parse ||= initialize_parse

