<?php
include("login.php");
if($login)
{
    $name=$_POST['nameBackup'];
    
    $back=$Mik->comm("/tool/user-manager/database/save",array(
        "name"=>$name
        ));
    
echo "done";
   //echo json_encode($arr);
//echo "<pre>";
 // print_r($pay);
}


