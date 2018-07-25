task default: %w{stg}

desc "start stg server"
task :stg do
  exec "shotgun --server=thin --port=3000 config.ru"
end

desc "start prod server"
task :prod do
  exec "thin start -s 4"
end

desc "stop all server"
task :stop do
  exec "for pidfile in tmp/pids/*.pid; do echo kill `cat $pidfile`; kill `cat $pidfile`; done"
end