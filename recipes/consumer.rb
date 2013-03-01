package "subversion"

include_recipe "runit"

include_recipe "python"

python_pip "pika" do
  # 0.9.9 is buggy and consumes 100% cpu. 0.9.10 will include the fix, but is unreleased, yet
  version "0.9.8"
  action :install
end

runit_service "mq-consumer-svn-create" do
  default_logger true
end

directory "/var/log/mq-consumer-svn-create"