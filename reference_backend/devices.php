<?php
include("login.php");
if($login)
{
    
    
    $pay=$Mik->comm("/tool/user-manager/payment/print");
    for($i=0;$i<count($pay);$i++)
    {
 $arr[$i]['user']=$pay[$i]['user'];
 $arr[$i]['result-msg']=$pay[$i]['result-msg'];
        
    }

   echo json_encode($arr);
//echo "<pre>";
 //  print_r($pay);
}
?>