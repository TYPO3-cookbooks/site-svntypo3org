sync_script = "/opt/svn-helpers/sync-groups.php"

package "php5-cli"

template sync_script do
  owner node[:apache][:user]
  group node[:apache][:group]
  source "groupsync/sync-groups.php"
  mode 00744
  variables(
    :authz_path => "/var/lib/svn/typo3v4/extensions/conf/authz",
    :hostname => "forge.typo3.org",
    # these are dummy credentials. they do not work!
    :token => "c66be699fbf763d050115fb729acdeaa5d122527"
  )
end


cron "sync-groups" do
  user node[:apache][:user]
  minute "33"
  command sync_script
end
