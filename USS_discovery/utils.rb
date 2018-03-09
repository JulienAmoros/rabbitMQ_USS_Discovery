require 'json'

module Utils
  def self.generate_log(body)
    msg = JSON.parse(body)
    "[#{Time.at(msg['timestamp'])}] #{msg['severity']} - #{msg['subject']}"
  end

  def self.generate_json(subject:, severity:, timestamp:)
    JSON.generate({ subject: subject, severity: severity, timestamp: timestamp })
  end
end
