package "subversion"

include_recipe "runit"

include_recipe "python"

python_pip "pika" do
  action :install
end

runit_service "mq-consumer-svn-create" do
  default_logger true
end

directory "/var/log/mq-consumer-svn-create"