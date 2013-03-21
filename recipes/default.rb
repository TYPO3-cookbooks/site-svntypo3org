

group "svntypo3org"

user "svntypo3org" do
  group "svntypo3org"
end

web_dir = "/var/www/vhosts/svn.typo3.org"
svn_dir = "/var/lib/svn"

[
  web_dir,
  web_dir + "/log",
  web_dir + "/www",
  svn_dir
].each do |dir|
  directory dir do
    recursive true
    owner node['apache']['user']
    group node['apache']['user']
    mode "0755"
  end
end


##############################################
# Redmine authentication & authorization
##############################################

auth_dir = "/opt/svn-helpers"

directory auth_dir do
  owner node['apache']['user']
  group node['apache']['group']
end

%w{
  apache-svn-authenticator.php
  helper-methods.php
}.each do |file|
  template "#{auth_dir}/#{file}" do
    source "auth/#{file}"
    owner node['apache']['user']
    group node['apache']['group']
    mode 0755
  end
end


package "libapache2-mod-authnz-external"
apache_module "authnz_external"

%w{
  libapache2-mod-perl2
  libapache-dbi-perl
  libdbd-mysql-perl
}.each do |pkg|
  package pkg
end
apache_module "perl"


# authorization
directory "/usr/lib/perl5/Apache/Authn/" do
  mode 0755
end

template "/usr/lib/perl5/Apache/Authn/Redmine.pm" do
  source "auth/Redmine.pm"
  mode 0644
end

forge_db_data = Hash.new

forge_role = node['site-svntypo3org']['forge_role']
if forge_role.nil?
  raise "You must specify a role to search for while finding the forge server in node[:site-svntypo3org][:forge_role], e.g. site-forgetypo3org"
end

# read the password from the node having role:site-forgetypo3org
search(:node, "role:" + forge_role) do |n|
  forge_db_data['host'] = n['fqdn']
  forge_db_data['user'] = n['site-forgetypo3org']['database_svn']['username']
  forge_db_data['pass'] = n['site-forgetypo3org']['database_svn']['password']
  forge_db_data['name'] = n['redmine']['database']['name']
end

##############################################
# SVN
##############################################

include_recipe "apache2::mod_dav_svn"
include_recipe "apache2::mod_ssl"

##############################################
# vhost
##############################################

ssl_certificate node['site-svntypo3org']['ssl_certificate']

web_app "svn.typo3.org" do
  server_name "svn.typo3.org"
  template "apache/web_app.erb"
  forge_db_host forge_db_data['host']
  forge_db_user forge_db_data['user']
  forge_db_pass forge_db_data['pass']
  forge_db_name forge_db_data['name']
  notifies :restart, "service[apache2]"
end

##############################################
# www data
##############################################

%w{
  README.html
  HEADER.html
}.each do |file|
  template "#{web_dir}/www/#{file}" do
    source "wwwroot/#{file}"
    owner node['apache']['user']
    group node['apache']['group']
  end
end

template "#{web_dir}/www/.htaccess" do
  source "wwwroot/htaccess"
  owner node['apache']['user']
  group node['apache']['group']
end

##############################################
# RabbitMQ consumer
##############################################
include_recipe "site-svntypo3org::consumer"