

group "svntypo3org"

user "svntypo3org" do
  group "svntypo3org"
end

web_dir = "/var/www/vhosts/#{node['site-svntypo3org']['hostname']}"
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

template "#{auth_dir}/apache-svn-authenticator.php" do
  source "auth/apache-svn-authenticator.php"
  owner node['apache']['user']
  group node['apache']['group']
  mode 0755
end

include_recipe "chef-vault"
apikey = chef_vault_password("typo3.org", "svntypo3org", "auth-apitoken")

template "#{auth_dir}/helper-methods.php" do
  source "auth/helper-methods.php"
  owner node['apache']['user']
  group node['apache']['group']
  mode 0755
  variables(:t3o_apikey => apikey)
end

# packages for external authentication
package "libapache2-mod-authnz-external"
apache_module "authnz_external"

# packages for svn authorization
package "libapache2-svn"

# the mods-available/authz_svn.load does not exist debian squeeze,
# instead the autzh_svn module is automatically loaded with dav_svn
apache_module "authz_svn" if node['platform'] == "debian" && node['platform_version'].to_i >= 7


##############################################
# SVN
##############################################

include_recipe "apache2::mod_dav_svn"
include_recipe "apache2::mod_ssl"

##############################################
# vhost
##############################################

ssl_certificate node['site-svntypo3org']['ssl_certificate']

web_app node['site-svntypo3org']['hostname'] do
  server_name node['site-svntypo3org']['hostname']
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