sync_script = "/opt/svn-helpers/sync-groups.php"
package "php5-cli"

if Chef::Config[:solo]
  Chef::Log.warn "Cannot read the API key of the svntypo3org with chef-solo"
  apikey = "token_not_set_with_chef_solo"

else

  # find the host name of the forge server
  forge_role = node['site-svntypo3org']['forge_role']
  if forge_role.nil?
    raise "You must specify a role to search for while finding the forge server in node['site-svntypo3org']['forge_role'], e.g. site-forgetypo3org"
  end
  # find the node having role:site-forgetypo3org
  forge_search_string = "role:" + forge_role
  forge_nodes = search(:node, forge_search_string)

  raise "Expected to find exactly 1 forge server by searching for '#{forge_search_string}', found #{forge_nodes.size}" unless forge_nodes.size.eql?(1)

  redmine_hostname = forge_nodes[0]['redmine']['hostname']

  include_recipe "chef-vault"
  # read API token from chef-vault
  apikey = chef_vault_password(redmine_hostname, "svntypo3org", "apitoken")

end

template sync_script do
  owner node['apache']['user']
  group node['apache']['group']
  source "groupsync/sync-groups.php"
  mode 00744
  variables(
    :authz_path => "/var/lib/svn/typo3v4/extensions/conf/authz",
    :hostname   => redmine_hostname,
    :token      => apikey
  )
end

cron "sync-groups" do
  user node['apache']['user']
  minute "33"
  command sync_script + " > /dev/null"
end
