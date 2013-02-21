<?php

/** not needed anymore
include('lib/class.tx_t3secsaltedpw_phpass.php');
*/


/**
* Check if supplied credentials are valid
* 
* @param string $user: Username
* @param string $password: Clear-text password
*/
function credentialsValid($user, $password) {
	$credentials = array(
		'apiKey' => '89e0793661446ddf3a89837012d91374f700973ab9935939a09332b34ed896c10b662ade5ef7cce974479957264c540a',
		'username' => $user,
		'password' => $password,
	);

	// Build Http query using params
	$postData = http_build_query($credentials);

	$header = array(
        	"Connection: close",
	        "Content-Length: " . strlen($postData),
	        "Content-Type: application/x-www-form-urlencoded",
	        "User-agent: Apache/SVN typo3org-authentication",
	);

	// Create Http context details
	$contextData = array (
	        'method'  => 'POST',
        	'header'  => implode("\r\n", $header) . "\r\n",
	        'content' => $postData
	);

	// Create context resource for our request
	$context = stream_context_create (array('http' => $contextData));

	$url = 'https://typo3.org/services/authenticate.php';

	return (file_get_contents($url, false, $context) === '1');
}


function userInAtLeastOneGroup($user, $groups) {
	$userProjects = explode(',', getUserProjects($user));
	file_put_contents('/tmp/test', getUserProjects($user));
	foreach ($groups as $group) {
		if (in_array($group, $userProjects)) {
			return TRUE;
		}
	}
	return FALSE;
}

/**
* Get projects for a user
* 
* @param string $user: Username
*/
function getUserProjects($user) {
	include('config/config.php');

	$dbh = new PDO('mysql:host='. $redmineConf['databaseHost'] . ';dbname=' . $redmineConf['databaseName'], $redmineConf['databaseUsername'], $redmineConf['databasePassword']);

	$groupList = array();

	$statement = $dbh->prepare('SELECT id, admin FROM users WHERE login=?');
	$statement->execute(array($user));
	$result = $statement->fetch(PDO::FETCH_ASSOC);
	if ($result['admin'] == 1) {
		$groupList[] = 'admin';
	}

	$statement = $dbh->prepare('SELECT projects.identifier AS identifier FROM projects JOIN members ON projects.id=members.project_id WHERE members.user_id=?');
	$statement->execute(array($result['id']));
	while($result = $statement->fetch(PDO::FETCH_ASSOC)) {
		$groupList[] = $result['identifier'];
	}

	return implode(',', $groupList);
}

/**
 * Get firstname, Lastname, and email from user
 */
function getUserData($user) {
	include('config/config.php');

	$dbh = new PDO('mysql:host='. $redmineConf['databaseHost'] . ';dbname=' . $redmineConf['databaseName'], $redmineConf['databaseUsername'], $redmineConf['databasePassword']);

	$statement = $dbh->prepare('SELECT id, firstname, lastname, mail, admin FROM users WHERE login=?');
	$statement->execute(array($user));
	$result = $statement->fetch(PDO::FETCH_ASSOC);
	if (!$result['id']) {
	    return array();
	}
	return array($result['firstname'], $result['lastname'], $result['mail'], $result['admin']);
	
}
?>
