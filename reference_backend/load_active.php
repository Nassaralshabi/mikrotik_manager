<?php
include("login.php");
if($login)
{
    
    
    $active=$Mik->comm("/ip/hotspot/active/print");
    for($i=0;$i<count($active);$i++)
    {
        if($active[$i]["session-time-left"]=="")
        {
$active[$i]["session-time-left"]="غير معروف";
        }
        
if($active[$i]["limit-bytes-total"]=="")
        {
$active[$i]["limit-bytes-total"]="0";
        }
    }

  echo json_encode($active);
//echo "<pre>";
 // print_r($active);
}
?>