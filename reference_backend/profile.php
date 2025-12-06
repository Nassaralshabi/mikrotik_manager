<?php
include("login.php");
if($login)
{
    
    $profile=$Mik->comm("/tool/user-manager/profile/print");
    echo json_encode($profile);
}
?>