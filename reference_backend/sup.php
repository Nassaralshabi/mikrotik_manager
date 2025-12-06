<?php
include("login.php");
if($login)
{
    
    $sup=$Mik->where("/tool/user-manager/user/print","location","1");
    for($i=0;$i<count($sup);$i++)
    {
        if($sup[$i]['last-name']=="")
        {
            $sup[$i]['last-name']=$sup[$i]['first-name'];
        }
        
if($sup[$i]['phone']=="")
        {
            $sup[$i]['phone']="";
        }
    }
   // echo "<pre>";
   // print_r($sup);
    
  echo json_encode($sup);
}
?>