module InitDetector

  def self.detect(session)
    if session.shell_command_token("ls /run/systemd/system 2>/dev/null").strip != ""
      return :systemd
    end

    pid1_path = session.shell_command_token("readlink /proc/1/exe 2>/dev/null").strip
    if pid1_path.include?('systemd')
      return :systemd
    elsif pid1_path.include?('init') || pid1_path.include?('sysvinit')
      return :sysvinit
    end

    pid1_name = session.shell_command_token("ps -p 1 -o comm= 2>/dev/null").strip
    if pid1_name == 'systemd'
      return :systemd
    elsif pid1_name == 'init'
      return :sysvinit
    end

    if session.shell_command_token("test -d /etc/init && echo 'upstart'").include?('upstart')
      return :unknown
    end

    if session.shell_command_token("test -d /etc/init.d && echo 'sysv'").include?('sysv')
      return :sysvinit
    end

    :unknown
  end
end
