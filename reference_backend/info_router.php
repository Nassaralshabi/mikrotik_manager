<?php
include("login.php");
if($login)
{
    
    $active=$Mik->comm("/ip/hotspot/active/print");
    $resourc=$Mik->comm("/system/resource/print");
$s=$Mik->comm("/system/routerboard/print");
    
    
    $ac=count($active);
    $cpu=$resourc[0]["cpu-load"];
    $uptime=$resourc[0]["uptime"];
    $serial=$s[0]["serial-number"];
  echo('[{"active":"'.$ac.'","cpu":"'.$cpu.'","uptime":"'.$uptime.'","serial-number":"'.$serial.'"}]');
}
?>