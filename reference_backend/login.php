<?php

include("api.php");
$login=false;
$Mik = new mik();
$user=$_POST['user'];
$pass=$_POST['pass'];
$ip=$_POST['ip'];
$Mik->port=$_POST['port'];

if($Mik->connect($ip,$user,$pass))
{
    $login=true;
    if(isset($_POST['login']))
    {
        
        echo("true");
    }
    
    
}else{
    
    
    if($api->error_str=="Connection refused"||$api->error_str=="Connection timed out")
    {

        echo "error connection";
    }elseif($api->error_str==""){
    
    echo "error pass";
    }else{
        echo "error";
    }
}






?>