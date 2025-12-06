<?php
include("login.php");
if($login)
{
    $id=$_POST['id'];
    
    $evi=$Mik->comm("/ip/hotspot/active/remove",array(
        ".id"=>$id
        ));
    
echo "done";
   //echo json_encode($arr);
//echo "<pre>";
 // print_r($pay);
}


