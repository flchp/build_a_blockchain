task default: %w{stg}

desc "start stg server"
task :stg do
  exec "shotgun --server=thin --port=3000 config.ru"
end

desc "start prod server"
task :prod do
  exec "thin start --port=3000"
end

