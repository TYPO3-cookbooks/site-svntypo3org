#!/usr/bin/php
<?php
/*
 synchronize group membership from forge (redmine) to SVN authz
*/

// makes the following roles a project member:
$allowedMemberTypes = array(
	'Leader',
	'Co-Leader',
	'Member',
	'Active Contributor',
);

// the user svntypo3org's redmine API token
$token = "<%= @token %>";

$hostname = "<%= @hostname %>";

$path = "<%= @authz_path %>";


/********************************************/


class GroupSync {
	protected $pdo;
	protected $requiredRoles = array();
	protected $accountIds = array();
	protected $usedGerritGroupTypes = array();
	protected $targetFile;
	protected $ssl = false;

	/** var string the URL without trailing / */
	protected $hostname = '';

	protected $apiToken = '';

	public function __construct() {
		ini_set('user_agent', 'SVN Group Sync Script');
	}

	public function setHostname($hostname) {
		$this->hostname = rtrim($hostname, '/');
		return $this;
	}

	public function setApiToken($token) {
		$this->apiToken = $token;
		return $this;
	}

	public function setRequiredRoles(array $allowedMemberTypes) {
		$this->requiredRoles = $allowedMemberTypes;
		return $this;
	}

	public function writeTo($path) {
		$this->targetFile = $path;
		return $this;
	}

	public function enableSsl() {
		$this->ssl = true;
		return $this;
	}

	public function sync() {
		$projects = $this->getAllProjects();

		echo "Received list of " . count($projects) . " projects\n";

		$projectsAndTheirMembers = array();

		foreach ($projects as $projectIdentifier) {
			echo "Processing project: " . $projectIdentifier . "\n";

			$members = $this->getMembersForProject($projectIdentifier);
			echo "Members: " . implode(",", $members) . "\n";

			$projectsAndTheirMembers[$projectIdentifier] = $members;
		}

		$file = $this->createAuthzFile($projectsAndTheirMembers);

		file_put_contents($this->targetFile, $file);

		return $this;
	}

	/**
	 * Reads all projects from redmine and returns a list of their identifiers
	 *
	 * @return array list of project identifiers
	 * @throws Exception
	 */
	protected function getAllProjects() {
		$url = "/projects.json?limit=100000";
		$projectData = json_decode(file_get_contents($this->getUrl() . $url));
		$projects = array();

		if (!is_object($projectData)) {
			throw new Exception("Did not receive a valid response while reading project data from " . $this->getUrl() . $url);
		}

		// read the project identifiers
		foreach ($projectData->projects as $project) {
			$projects[] = $project->identifier;
		}

		if ($projectData->total_count != count($projects)) {
			throw new Exception("Something is weird, redmine said we have " . $projectData->total_count . " projects, but we got " . count($projects));
		}

		// a list of project identifiers
		return $projects;
	}


	/**
	 * Returns all the members of the project which should have write access
	 *
	 * @param $identifier string project identifier
	 * @return array list of members
	 * @throws Exception
	 */
	protected function getMembersForProject($identifier) {
		$url = '/projects/' . $identifier . '/memberships.json';

		$membershipData = json_decode(file_get_contents($this->getUrl(true) . $url));

		$members = array();

		foreach ($membershipData->memberships as $membership) {

			echo "Processing user '" . $membership->user->name . "'\n";

			// read the role objects
			$roles = array();
			foreach ($membership->roles as $role) {
				$roles[] = $role->name;
			}

			if ($this->rolesPermitAccess($roles)) {

				if (!isset($membership->user->login)) {
					throw new Exception("The membership.json did not return a 'login' entry for the user " . $membership->user->name . ". Have you installed our typo3_api plugin, which adds this information?");
				}

				$members[] = $membership->user->login;
			}
		}

		return $members;
	}

	protected function getUrl($authenticated = false) {
		$protocol = $this->ssl ? "https" : "http";
		$credentials = $authenticated ? ($this->apiToken . ":passwordDoesNotMatter@") : "";

		return $protocol . "://" . $credentials . $this->hostname;
	}

	/**
	 * Checks if $rolesOfTheUser include at least one of the $requiredRoles to be listed as a team member
	 *
	 * @var array $rolesOfTheUser array of roles of a user to check
	 * @return bool true $rolesOfTheUser contains at least one of the $required roles
	 */
	protected function rolesPermitAccess(array $rolesOfTheUser) {
		echo "User has roles:" . implode(",", $rolesOfTheUser) ."\n";

		foreach ($this->requiredRoles as $requiredRole) {

			// we search for any of the required roles to be listed as a member
			if (in_array($requiredRole, $rolesOfTheUser)) {
				echo "User is ALLOWED\n";
				return true;
			}
		}

		echo "Could not find any of " . implode(",", $this->requiredRoles). "\n";
		return false;
	}

	/**
	 * @param $projectsAndMembers array with keys the project identifiers and values an array of login names of members
	 * @return string file contens for the authz file, like this:
	 * [groups]
	 * admins = john, inge, dieter
	 * extension-gimmefive-developers = jocrau, ohader
	 * extension-contentparser-developers = jocrau
	 *
	 * [/gimmefive]
	 * @extension-gimmefive-developers = rw
	 *
	 * [/contentparser]
	 * @extension-contentparser-developers = rw
	 *
	 * [/]
	 * @admins = rw
	 * * = r
	 *
	 * */
	protected function createAuthzFile($projectsAndMembers) {

		$lines = array();
		$lines[] = "[groups]";
		$lines[] = "admins = mstucki, stephenking, jugglepro, ohader";

		foreach ($projectsAndMembers as $projectIdentifier => $members) {
			$lines[] = $projectIdentifier . " = " . implode(", ", $members);
		}

		// add some space
		$lines[] = "";
		$lines[] = "";

		foreach ($projectsAndMembers as $projectIdentifier => $members) {
			$extensionKey = str_replace("extension-", "", $projectIdentifier);

			$lines[] = "[/$extensionKey]";
			$lines[] = "@$projectIdentifier = rw";
			$lines[] = "";
		}

		$lines[] = "[/]";
		$lines[] = "@admins = rw";
		$lines[] = "* = r";

		return implode("\n", $lines);
	}

}

$sync = new GroupSync();
$sync->setRequiredRoles($allowedMemberTypes)
	->setHostname($hostname)
	->setApiToken($token)
	->enableSsl()
	->writeTo($path)
	->sync();










?>
