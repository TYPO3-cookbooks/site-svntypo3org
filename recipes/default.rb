

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


# packages for external authentication
package "libapache2-mod-authnz-external"
apache_module "authnz_external"

# packages for svn authorization
package "libapache2-svn"


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
# Group sync
##############################################
include_recipe "site-svntypo3org::groupsync"