<?php
function cheek1($str)
{
    
    if($str=="")
    {
        return 0;
    }else{
        return $str;
    }
}



include("login.php");
if($login)
{
    
    
    $profile=$Mik->comm("/tool/user-manager/profile/print");
$limit=$Mik->comm("/tool/user-manager/profile/limitation/print");
$profile_limit=$Mik->comm("/tool/user-manager/profile/profile-limitation/print");

for($i=0;$i<count($profile_limit);$i++)
{
$p_l['name'][$profile_limit[$i]['profile']]=$profile_limit[$i]['limitation'];
$p_l['id'][$profile_limit[$i]['profile']]=$profile_limit[$i]['.id'];
    
}
for($i=0;$i<count($limit);$i++)
    
    {
        $l[$limit[$i]['name']]['down']=$limit[$i]['download-limit'];
$l[$limit[$i]['name']]['up']=$limit[$i]['upload-limit'];
$l[$limit[$i]['name']]['trans']=$limit[$i]['transfer-limit'];
        
        
$l[$limit[$i]['name']]['uptime']=$limit[$i]['uptime-limit'];

$l[$limit[$i]['name']]['.id']=$limit[$i]['.id'];
 }

for($i=0;$i<count($profile);$i++)
{
    
$profile[$i]['down']=cheek1($l[$p_l['name'][$profile[$i]['name']]]['down']);
$profile[$i]['up']=cheek1( $l[$p_l['name'][$profile[$i]['name']]]['up']);

$profile[$i]['trans']=cheek1($l[$p_l['name'][$profile[$i]['name']]]['trans']);

$profile[$i]['uptime']=cheek1($l[$p_l['name'][$profile[$i]['name']]]['uptime']);

$profile[$i]['id-limit']=$l[$p_l['name'][$profile[$i]['name']]]['.id'];
$profile[$i]['id-profile-limit']=$p_l['id'][$profile[$i]['name']];

    
}

  echo json_encode($profile);
//echo "<pre>";
 //print_r($profile);
}
?>