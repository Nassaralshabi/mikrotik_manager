<?php
include("login.php");
if($login)
{
    
    $ses=$Mik->comm("/tool/user-manager/session/print");
for($i=0;$i<count($pay);$i++)
    {
 $arr[$i]['user']=$ses[$i]['user'];
 $arr[$i]['from-time']=$pay[$i]['from-time'];
        
    }
    echo json_encode($arr);
    //echo "<pre>";
  //  print_r($ses);
}
?>