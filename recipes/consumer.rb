package "subversion"

include_recipe "runit"

include_recipe "python"

python_pip "pika" do
  action :install
end

# remove pre- from environment (if we're eg in pre-production, which almost equals production)
environment = node.chef_environment.gsub(/pre-/, '')

# get all passwords for this environment
all_password_data = Chef::EncryptedDataBagItem.load("passwords", environment)

# remove . from fqdn
server_cleaned = node['site-svntypo3org']['amqp']['server'].gsub(/\./, "")
user = node['site-svntypo3org']['amqp']['user']

Chef::Log.info "Looking for password rabbitmq.#{server_cleaned}.#{}"
if all_password_data["rabbitmq"][server_cleaned][user].nil?
  raise "Cannot find password for rabbitmq user '#{user}' in data bag 'passwords/#{node.chef_environment}'."
end

amqp_pass = all_password_data["rabbitmq"][server_cleaned][user]

runit_service "mq-consumer-svn-create" do
  default_logger true
  options({
    :amqp_server   => node['site-svntypo3org']['amqp']['server'],
    :amqp_user     => node['site-svntypo3org']['amqp']['user'],
    :amqp_vhost    => node['site-svntypo3org']['amqp']['vhost'],
    :amqp_password => amqp_pass
  })
end

directory "/var/log/mq-consumer-svn-create"