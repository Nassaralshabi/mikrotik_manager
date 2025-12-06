<?php
include("login.php");
if($login)
{
    $user_finished=json_decode($_POST['user_finished'],true);
for($i=0;$i<count($user_finished);$i++)
{
    if($user_finished[$i]['select']=="1")
    {
    $remove=$Mik->comm("/tool/user-manager/user/remove",array(
        ".id"=>$user_finished[$i]['id']
        ));
    }
}
   echo ("finish");
//echo "<pre>";
 //  print_r($pay);
}
?>