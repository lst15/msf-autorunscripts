module InitDetector
  def self.detect(session)
    # --- systemd ---
    return :systemd if session.shell_command_token("test -d /run/systemd/system && echo yes").strip == "yes"
    return :systemd if session.shell_command_token("readlink /proc/1/exe 2>/dev/null").include?("systemd")
    return :systemd if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "systemd"
    return :systemd if session.shell_command_token("which systemctl 2>/dev/null").strip != ""

    # --- sysvinit ---
    if session.shell_command_token("test -d /etc/init.d && echo yes").strip == "yes"
      return :sysvinit
    end
    if session.shell_command_token("readlink /proc/1/exe 2>/dev/null") =~ /init|sysvinit/
      return :sysvinit
    end
    if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "init"
      return :sysvinit
    end

    # --- upstart ---
    return :upstart if session.shell_command_token("test -d /etc/init && echo yes").strip == "yes"
    return :upstart if session.shell_command_token("readlink /proc/1/exe 2>/dev/null").include?("upstart")
    return :upstart if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "upstart"

    # --- openrc ---
    return :openrc if session.shell_command_token("test -d /run/openrc && echo yes").strip == "yes"
    return :openrc if session.shell_command_token("which openrc-init 2>/dev/null").strip != ""
    return :openrc if session.shell_command_token("which rc-service 2>/dev/null").strip != ""
    return :openrc if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "openrc-init"

    # --- runit ---
    return :runit if session.shell_command_token("test -d /etc/runit && echo yes").strip == "yes"
    return :runit if session.shell_command_token("which runit 2>/dev/null").strip != ""
    return :runit if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "runit"

    # --- s6 ---
    return :s6 if session.shell_command_token("which s6-svscan 2>/dev/null").strip != ""
    return :s6 if session.shell_command_token("pgrep -f s6-svscan 2>/dev/null").strip != ""
    return :s6 if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "s6-svscan"

    # --- dinit ---
    return :dinit if session.shell_command_token("which dinit 2>/dev/null").strip != ""
    return :dinit if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "dinit"

    # --- shepherd (GNU Guix) ---
    return :shepherd if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "shepherd"
    return :shepherd if session.shell_command_token("which herd 2>/dev/null").strip != ""

    # --- busybox init ---
    if session.shell_command_token("readlink /proc/1/exe 2>/dev/null") =~ /busybox/
      return :busybox
    end
    if session.shell_command_token("cat /proc/1/comm 2>/dev/null").strip == "busybox"
      return :busybox
    end

    # --- launchd (macOS) ---
    return :launchd if session.shell_command_token("uname").strip == "Darwin"

    # --- SMF (Solaris) ---
    return :smf if session.shell_command_token("uname").strip == "SunOS"

    # --- Windows SCM (caso esteja rodando Meterpreter Windows) ---
    if session.platform =~ /win/i
      return :windows_scm
    end

    # --- Android init ---
    return :android_init if session.shell_command_token("getprop 2>/dev/null").strip != ""

    # ---BSD rc.d (FreeBSD, OpenBSD, NetBSD)---
    if session.shell_command_token("uname").strip =~ /FreeBSD|OpenBSD|NetBSD/
      return :bsd_rc
    end

    # fallback
    :unknown
  end
end
