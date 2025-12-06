<?php

function convertToBite($str)
{
if(substr($str,strlen($str)-1,1)=="G")
    {
        $GB=substr($str,0,strlen($str)-1);
        return $GB*1024*1024*1024;
        
    }
else if(substr($str,strlen($str)-1,1)=="M")
{
$MB=substr($str,0,strlen($str)-1);
        return $MB*1024*1024;
    
}
   
    return 0;
}


include("login.php");
if($login)
{
    $owner=$_POST['owner'];
    $name=$_POST['name'];
    $starts=$_POST['starts'];
    $over=$_POST['over'];
    $price=$_POST['price'];
    $validity=$_POST['validity'];
    $down=convertToBite($_POST['down']);
    $up=convertToBite($_POST['up']);
    $up_down=convertToBite( $_POST['up_down']);
    $uptime=$_POST['uptime'];
    $id_profile=$_POST['id_profile'];
    $id_limit=$_POST['id_limit'];
    $id_profile_limit=$_POST['id_profile_limit'];

//echo $id_profile_limit;
    
    $set1=$Mik->comm("/tool/user-manager/profile/set",array(
        "name"=>$name,
        "name-for-users"=>$name,
        "owner"=>$owner,
        "override-shared-users"=>$over,
        "price"=>$price,
        "validity"=>$validity,
        "starts-at"=>$starts,
        "numbers"=>$id_profile
        ));

        
 
    $set2=$Mik->comm("/tool/user-manager/profile/limitation/set",array(

        "name"=>$name,
        "owner"=>$owner,
        "download-limit"=>$down,
        "upload-limit"=>$up,
        "transfer-limit"=>$up_down,
        "uptime-limit"=>$uptime,
        ".id"=>$id_limit
        
        ));
 
    
    
        

        echo "done";
//echo "<pre>";
//print_r($set1);
//print_r($set2);
    
}
?>