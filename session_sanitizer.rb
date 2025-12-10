# Cleans up active sessions for the target.
# 1. Detects and terminates duplicate sessions from the same IP.
# 2. Provides a minimal API for session-level hygiene.

module SessionSanitizer
  def self.extract_ip(sess)
    stream =
      if sess.respond_to?(:sock)
        sess.sock
      elsif sess.respond_to?(:rstream)
        sess.rstream
      end
    return nil unless stream

    begin
      peer = stream.peerinfo
      peer&.split(':')&.first
    rescue IOError, Errno::ENOTCONN
      nil
    end
  end

  def self.run(fm, target_ip, current_sid)
    fm.sessions.each do |sid, sess|
      next if sid == current_sid
      ip = extract_ip(sess)
      next unless ip == target_ip

      print_error("Killing duplicate session ID #{sid} for IP #{target_ip}")
      sess.kill
    end
  end
end
