<?php
include("login.php");
if($login)
{
    
    
    $user=$Mik->comm("/tool/user-manager/user/print");
    $sum=count($user);
    $end=0;
    $used=0;
    $noused=0;
    for($i=0;$i<count($user);$i++)
    {
  if($user[$i]['last-seen']=="never")
  {
      $noused++;
      
  }else{
      $used++;
  }
  if($user[$i]['actual-profile']=="")
  {
      $end++;
  }
    }
    
    $arr[0]['used']=($used/$sum)*100;
    $arr[0]['end']=($end/$sum)*100;
    $arr[0]['u']=$used;
    $arr[0]['e']=$end;
    $arr[0]['nu']=$noused;
   // $arr[0]['all']=$sum;
    
   echo json_encode($arr);

}
?>