<?php
include("login.php");
if($login)
{
    
    $users=$Mik->comm("/tool/user-manager/user/print");
    for($i=0;$i<count($users);$i++)
    {
if($users[$i]['active-sessions']=="")
    {
        
    $users[$i]['active-sessions']="0";
    } 
if($users[$i]['upload-used']=="")
    {
        
    $users[$i]['upload-used']="0";
    }  
if($users[$i]['actual-profile']=="")
    {
        
    $users[$i]['actual-profile']="منتهي";
    }   
if($users[$i]['download-used']=="")
    {
        
    $users[$i]['download-used']="0";
    }  
    
if($users[$i]['last-seen']=="")
    {
        
    $users[$i]['last-seen']="0";
    }   
if($users[$i]['caller-id']=="")
    {
        
    $users[$i]['caller-id']="0";
    }    
if($users[$i]['uptime-used']=="")
    {
        
    $users[$i]['uptime-used']="";
    }    
    }
    
    
   echo json_encode($users);
  
   // echo "<pre>";
   // print_r($users);
}
?>