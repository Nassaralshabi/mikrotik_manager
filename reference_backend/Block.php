<?php
include("login.php");
if($login)
{
    $mac=$_POST['mac'];
    
$bloc=$Mik->comm("/ip/hotspot/ip-binding/add",array(
        "mac-address"=>$mac,
        "type"=>"blocked"
        ));
    
echo "done";
   //echo json_encode($arr);
//echo "<pre>";
 // print_r($pay);
}


