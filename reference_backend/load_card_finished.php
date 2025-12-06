<?php
function filter($str)
{
    $newStr="";
    for($i=0;$i<strlen($str);$i++)
    {
        if(substr($str,$i,1)==".")
        {
            return $newStr;
        }else{
            $newStr=$newStr.substr($str,$i,1);
        }
    }
    return $newStr;
    
}
include("login.php");

//echo filter("250.000000");
if($login)
{
    $profile=$_POST['profile'];
    $hoer=$_POST['hoer'];
    $down=$_POST['down'];
    if(isset($_POST['p']))
    {
        
$finished=$Mik->where("/tool/user-manager/user/print","actual-profile","");
    
    
    
  //  print_r($finished[1]);
    
    $n=0;
for($i=0;$i<count($finished);$i++)
{
$d=($finished[$i]['download-used']+$finished[$i]['upload-used'])/1024/1024;

$h=$finished[$i]['uptime-used'];

    
    $fin[$n]['down']=filter($d)."MB";
    $fin[$n]['uptime']=$h;
    $fin[$n]['user']=$finished[$i]['username'];
    $fin[$n]['select']="1";
    $n++;



    
}

echo json_encode($fin);
        
    }
    else{
    $finished=$Mik->where("/tool/user-manager/user/print","actual-profile",$profile);
    
    
    
  //  print_r($finished[1]);
    
    $n=0;
for($i=0;$i<count($finished);$i++)
{
$d=($finished[$i]['download-used']+$finished[$i]['upload-used'])/1024/1024;

$h=$finished[$i]['uptime-used'];
if(filter($d)==$down || $h==$hoer)
{
    
    $fin[$n]['down']=filter($d)."MB";
    $fin[$n]['uptime']=$h;
    $fin[$n]['user']=$finished[$i]['username'];
    $fin[$n]['select']="1";
    $n++;
}


    
}

echo json_encode($fin);
}}
?>



