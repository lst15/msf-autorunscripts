module InitDetector
  def self.detect(session)
    begin
      # Cache de comandos comuns para evitar múltiplas execuções
      cache = build_cache(session)
      
      # Detecção em ordem de prioridade (mais específico -> mais genérico)
      
      # --- Casos especiais: containers e processos não-init ---
      return :dockerinit if cache[:proc1_exe].include?("docker")
      return :node if cache[:proc1_exe].include?("node")
      return :container_minimal if cache[:proc1_comm] =~ /^(sh|bash|app|python|ruby|java)$/
      
      # --- Plataformas específicas (verificar antes de init systems Linux) ---
      # Windows
      return :windows_scm if session.platform =~ /win/i
      
      # macOS
      return :launchd if cache[:uname] == "Darwin"
      
      # Solaris
      return :smf if cache[:uname] == "SunOS"
      
      # Android
      return :android_init if cache[:has_getprop]
      
      # WSL (Windows Subsystem for Linux)
      if cache[:uname_release] =~ /Microsoft|microsoft|WSL/
        return :systemd if cache[:proc1_comm] == "systemd"
        return :wsl_init if cache[:proc1_comm] == "init"
      end
      
      # BSD (FreeBSD, OpenBSD, NetBSD, DragonFly)
      if cache[:uname] =~ /FreeBSD|OpenBSD|NetBSD|DragonFly/
        return :bsd_rc if cache[:has_rc_conf]
        return :bsd_rc # fallback para BSD
      end
      
      # --- systemd (mais comum em distribuições modernas) ---
      return :systemd if cache[:has_systemd_dir]
      return :systemd if cache[:proc1_exe].include?("systemd")
      return :systemd if cache[:proc1_comm] == "systemd"
      return :systemd if cache[:has_systemctl]
      
      # --- OpenRC (Alpine, Gentoo, etc.) ---
      return :openrc if cache[:has_openrc_dir]
      return :openrc if cache[:proc1_comm] == "openrc-init"
      return :openrc if cache[:has_openrc_init]
      return :openrc if cache[:has_rc_service]
      return :openrc if cache[:has_openrc]
      
      # --- runit (Void Linux, etc.) ---
      return :runit if cache[:has_runit_dir]
      return :runit if cache[:proc1_comm] == "runit"
      return :runit if cache[:proc1_comm] == "runit-init"
      return :runit if cache[:has_runit]
      
      # --- s6 ---
      return :s6 if cache[:proc1_comm] == "s6-svscan"
      return :s6 if cache[:has_s6_svscan]
      return :s6 if cache[:pgrep_s6] != ""
      
      # --- dinit ---
      return :dinit if cache[:proc1_comm] == "dinit"
      return :dinit if cache[:has_dinit]
      
      # --- shepherd (GNU Guix) ---
      return :shepherd if cache[:proc1_comm] == "shepherd"
      return :shepherd if cache[:has_herd]
      
      # --- busybox init ---
      return :busybox if cache[:proc1_exe] =~ /busybox/
      return :busybox if cache[:proc1_comm] == "busybox"
      
      # --- upstart (Ubuntu antigo) ---
      return :upstart if cache[:has_upstart_dir]
      return :upstart if cache[:proc1_exe].include?("upstart")
      return :upstart if cache[:proc1_comm] == "upstart"
      
      # --- sysvinit (verificar por último, é o mais genérico) ---
      # Cuidado: /etc/init.d existe em muitos sistemas com systemd
      return :sysvinit if cache[:proc1_exe] =~ /sysvinit/
      return :sysvinit if cache[:proc1_comm] == "init" && !cache[:has_systemd_dir]
      return :sysvinit if cache[:has_initd_dir] && !cache[:has_systemd_dir] && !cache[:has_openrc_dir]
      
      # --- fallback ---
      :unknown
      
    rescue => e
      # Log do erro se necessário
      # puts "Error detecting init: #{e.message}"
      :unknown
    end
  end
  
  private
  
  def self.build_cache(session)
    {
      # Informações do processo PID 1
      proc1_exe: safe_command(session, "readlink /proc/1/exe 2>/dev/null"),
      proc1_comm: safe_command(session, "cat /proc/1/comm 2>/dev/null"),
      
      # Informações do sistema
      uname: safe_command(session, "uname -s"),
      uname_release: safe_command(session, "uname -r"),
      
      # Diretórios característicos
      has_systemd_dir: dir_exists?(session, "/run/systemd/system"),
      has_openrc_dir: dir_exists?(session, "/run/openrc"),
      has_runit_dir: dir_exists?(session, "/etc/runit"),
      has_upstart_dir: dir_exists?(session, "/etc/init"),
      has_initd_dir: dir_exists?(session, "/etc/init.d"),
      has_rc_conf: file_exists?(session, "/etc/rc.conf"),
      
      # Binários disponíveis
      has_systemctl: command_exists?(session, "systemctl"),
      has_openrc_init: command_exists?(session, "openrc-init"),
      has_rc_service: command_exists?(session, "rc-service"),
      has_openrc: command_exists?(session, "openrc"),
      has_runit: command_exists?(session, "runit"),
      has_s6_svscan: command_exists?(session, "s6-svscan"),
      has_dinit: command_exists?(session, "dinit"),
      has_herd: command_exists?(session, "herd"),
      has_getprop: command_exists?(session, "getprop"),
      
      # Processos em execução
      pgrep_s6: safe_command(session, "pgrep -f s6-svscan 2>/dev/null")
    }
  end
  
  def self.safe_command(session, cmd)
    session.shell_command_token(cmd).strip
  rescue
    ""
  end
  
  def self.dir_exists?(session, path)
    safe_command(session, "test -d #{path} && echo yes") == "yes"
  end
  
  def self.file_exists?(session, path)
    safe_command(session, "test -f #{path} && echo yes") == "yes"
  end
  
  def self.command_exists?(session, cmd)
    safe_command(session, "which #{cmd} 2>/dev/null") != ""
  end
end
