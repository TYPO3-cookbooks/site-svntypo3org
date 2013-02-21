#!/usr/bin/env php5
<?php

require('helper-methods.php');

error_reporting(E_ALL);
ini_set('display_errors', '1');
ini_set('display_startup_errors', '1');

$fp = fopen('php://stdin', 'r');

$user = trim(fgets($fp, 4096));
$password = trim(fgets($fp, 4096));

if (credentialsValid($user, $password)) {
	exit(0);
} else {
	exit(1);
}

?>
