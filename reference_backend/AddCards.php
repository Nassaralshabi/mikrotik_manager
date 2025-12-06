<?php
include("login.php");
if($login)
{
$cards=json_decode($_POST['cards'],true);
//$customer=$_POST['customer'];
//$profile=$_POST['profile'];
//$idSup=$_POST['idSup'];
    
for($i=0;$i<count($cards);$i++)
{
    
    if($cards[$i]['select']==1)
    {
        
    
    $add1=$Mik->comm("/tool/user-manager/user/add",array(
        "username"=>$cards[$i]['user'],
        "password"=>$cards[$i]['pass'],
        "customer"=>$cards[$i]['castomer'],
        "caller-id-bind-on-first-use"=>$cards[$i]['callerId']
        ));
        //print_r($add1);
//$id=$Mik->where("/tool/user-manager/user/print","username",$cards[$i]['user']);
/*
    do
    {
     $id=$Mik->where("/tool/user-manager/user/print","username",$cards[$i]['user']);
    }while($id[count($id)-1]['.id']=="");
    
    */
    
   if($add1[0]!="")
    {
$add2=$Mik->comm("/tool/user-manager/user/create-and-activate-profile",array(
        "profile"=>$cards[$i]['profile'],
        "customer"=>$cards[$i]['customer'],
        ".id"=>$add1
        ));
        
    }else{
        echo "error";
    }
   
   
   
   if($cards[$i]['idSup']!="")
   {
        do
    {
     $id2=$Mik->where("/tool/user-manager/payment/print","user",$cards[$i]['user']);
     
    }while($id2[0]['.id']=="");
     
   


$add2=$Mik->comm("/tool/user-manager/payment/set",array(
        "result-msg"=>$cards[$i]['idSup'],
        ".id"=>$id2[count($id2)-1]['.id']
        ));
       
   }
   
 
        
        
        
    }
    
}


    echo "done";      
      
}
?>



