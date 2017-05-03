<?php

#----------------------------------------------------------------------
function generateNewPassword ( $id, $randomString ) {
#----------------------------------------------------------------------

  return sha1( $id . "foobidoo" . $randomString . wcaDate() );
}

#----------------------------------------------------------------------
function databaseTableExists ( $tableName ) {
#----------------------------------------------------------------------

  return count( dbQuery( "SHOW TABLES LIKE '$tableName'" )) == 1;
}

#----------------------------------------------------------------------
function echoAndFlush ( $text ) {
#----------------------------------------------------------------------

  echo $text;
  ob_flush();
  flush();
}

?>
