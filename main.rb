require '/home/msf/session_sanitizer'
require '/home/msf/shell_promotion'

fm        = client.framework
target_ip = client.session_host
sid       = client.sid

print("\n\n")
SessionSanitizer.run(fm, target_ip, sid)
print("\n")
ShellPromotion.run(fm, sid, target_ip, client)
print("\n")
