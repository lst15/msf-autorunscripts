# Renames an active session using the first service title returned by Shodan.
# 1. Queries the Shodan host search API with the target IP.
# 2. Extracts the first available title field.
# 3. Applies the title to the active session matching the IP.

require 'json'
require 'net/http'
require 'uri'

require '/home/msf/session_sanitizer'

module ShodanTitleRenamer
  ENDPOINT = 'https://api.shodan.io/shodan/host/search'.freeze
  DEFAULT_TIMEOUT = 3
  NO_KEY = "Shodan API key not provided; skipping rename.".freeze
  NO_MATCH = "No active session for %s; skipping rename.".freeze

  def self.run(fm, target_ip, api_key: ENV['SHODAN_API_KEY'], logger: nil)
    return log(logger, NO_KEY) if api_key.nil? || api_key.empty?

    title = fetch_title(target_ip, api_key, logger)
    return unless title

    sid, sess = locate_session(fm, target_ip)
    return log(logger, NO_MATCH % target_ip) unless sess

    rename_session(sess, sid, title, logger)
  end

  def self.fetch_title(target_ip, api_key, logger)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(key: api_key, query: "ip:\"#{target_ip}\"")

    resp = perform_request(uri, logger)
    return unless resp.is_a?(Net::HTTPSuccess)

    parse_title(resp.body, logger)
  end

  def self.parse_title(body, logger)
    json = JSON.parse(body) rescue nil
    return log(logger, "Invalid JSON from Shodan") unless json

    matches = json['matches']
    return unless matches.is_a?(Array)

    extract_title(matches)
  end

  def self.extract_title(matches)
    matches.each do |entry|
      t = entry['title']
      return t unless t.to_s.empty?

      t = entry.dig('http', 'title')
      return t unless t.to_s.empty?
    end
    nil
  end

  def self.perform_request(uri, logger)
    Net::HTTP.start(uri.host, uri.port,
      open_timeout: DEFAULT_TIMEOUT,
      read_timeout: DEFAULT_TIMEOUT,
      use_ssl: (uri.scheme == 'https')
    ) do |http|
      http.request(Net::HTTP::Get.new(uri))
    end
  rescue => e
    log(logger, "Shodan request error: #{e.message}")
    nil
  end

  def self.locate_session(fm, target_ip)
    fm.sessions.each do |sid, sess|
      ip = sess.session_host rescue nil
      ip ||= SessionSanitizer.extract_ip(sess)
      return [sid, sess] if ip == target_ip
    end
    [nil, nil]
  end

  def self.rename_session(sess, sid, title, logger)
    if sess.respond_to?(:info=)
      sess.info = title
    elsif sess.respond_to?(:desc=)
      sess.desc = title
    else
      return log(logger, "Session #{sid} does not support renaming.")
    end

    log(logger, "Session #{sid} renamed to '#{title}'.")
  rescue => e
    log(logger, "Rename failed for session #{sid}: #{e.message}")
  end

  def self.log(logger, msg)
    return logger.print_status(msg) if logger&.respond_to?(:print_status)
    return logger.puts(msg) if logger&.respond_to?(:puts)
    $stdout.puts(msg)
  end
end
