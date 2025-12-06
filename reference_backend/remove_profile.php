<?php



include("login.php");
if($login)
{
    /*
    $owner=$_POST['owner'];
    $name=$_POST['name'];
    $starts=$_POST['starts'];
    $over=$_POST['over'];
    $price=$_POST['price'];
    $validity=$_POST['validity'];
    $down=convertToBite($_POST['down']);
    $up=convertToBite($_POST['up']);
    $up_down=convertToBite( $_POST['up_down']);
    $uptime=$_POST['uptime'];*/
    $id_profile=$_POST['id_profile'];
    $id_limit=$_POST['id_limit'];
    $id_profile_limit=$_POST['id_profile_limit'];

$remove3=$Mik->comm("/tool/user-manager/profile/profile-limitation/remove",array(

    "numbers"=>$id_profile_limit
        ));
    
    
    $remove1=$Mik->comm("/tool/user-manager/profile/remove",array(

        "numbers"=>$id_profile
        ));

        
 
    $remove2=$Mik->comm("/tool/user-manager/profile/limitation/remove",array(


        "numbers"=>$id_limit
        
        ));
 
    
    
echo "done";        

        
//echo "<pre>";
//print_r($remove1);
//print_r($remove2);
//print_r($remove3);
    
}
?>