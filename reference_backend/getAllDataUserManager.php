<?php


function dateFormat($str)
{
$month=array(
    "jan"=>"01",
    "feb"=>"02",
   "mar"=>"03",
   "apr"=>"04",
   "may"=>"05",
   "jun"=>"06",
   "jul"=>"07",
   "aug"=>"08",
   "sep"=>"09",
   "oct"=>"10",
   "nov"=>"11",
   "dec"=>"12"
    );
    $y=substr($str,7,4);
    $m=$month[substr($str,0,3)];
    $d=substr($str,4,2);
    return $y."/".$m."/".$d;
}

include("login.php");
$used=array();
if($login)
{
    
    
    $pay=$Mik->comm("/tool/user-manager/payment/print");
    $users=$Mik->comm("/tool/user-manager/user/print");
     $ses=$Mik->comm("/tool/user-manager/session/print");
     //------
     
     
    for($i=0;$i<count($users);$i++)
    {
if($users[$i]['active-sessions']=="")
    {
        
    $users[$i]['active-sessions']="0";
    } 
if($users[$i]['upload-used']=="")
    {
        
    $users[$i]['upload-used']="0";
    }  
if($users[$i]['actual-profile']=="")
    {
        
    $users[$i]['actual-profile']="";
    }  
    
if($users[$i]['actual-profile']=="deleted")
    {
        
 $users[$i]['actual-profile']="_deleted";
    }   
    
    
if($users[$i]['download-used']=="")
    {
        
    $users[$i]['download-used']="0";
    }  
    

if($users[$i]['caller-id']=="")
    {
        
    $users[$i]['caller-id']="";
    }    
if($users[$i]['uptime-used']=="")
    {
        
    $users[$i]['uptime-used']="";
    }    
    }
     
     
     
     //-------
     
     
     
     
    $u=0;
    for($i=0;$i<count($pay);$i++)
    {
        
 $pay[$i]['trans-start']=dateFormat($pay[$i]['trans-start']);
        
        
for($j=0;$j<count($users);$j++)
{
  if($users[$j]['username']==$pay[$i]['user'])
  {
      if($users[$j]['last-seen']=="never")
      {
      $pay[$i]['used']="no";
      break;
      }else{
      $pay[$i]['used']="yes";
      $used[$u]['user']=$pay[$i]['user'];
$used[$u]['index']=$i;
      $u++;
      break;
      }
      
      
  }
}
            
  }
 // sort($ses);
  $str="";
  $s=0;
  $arr=[];
  $tmp=[];
  $download=0;
  $uploud=0;
  $tmpd=[];
  $d=0;
  $reports=[];
  for($i=0;$i<count($ses);$i++)
  {
      
      /*
      
  if(strtolower(date("M/d/Y"))==substr($ses[$i]['from-time'],0,11))
      
      {
 $date=strtolower(date("M/d/Y"));
$download+=$ses[$i]['download'];
$upload+=$ses[$i]['upload'];
      }
      */
      
      
      
 if(!in_array($ses[$i]['user'],$tmp))
      {
          $tmp[$s]=$ses[$i]['user'];
          $arr[$s]['user']=$tmp[$s];
          $arr[$s]['date']=dateFormat($ses[$i]['from-time']);
          $s++;
          
      }
      
      
      //------
      
if($tmpd[dateFormat($ses[$i]['from-time'])]=="")
      {
          $tmpd[dateFormat($ses[$i]['from-time'])]=$d;
          
$reports[$d]['date']=dateFormat($ses[$i]['from-time']);
$reports[$d]['download']=$ses[$i]['download'];
$reports[$d]['upload']=$ses[$i]['upload'];
          $d++;
      }else{
          
          
$reports[$tmpd[dateFormat($ses[$i]['from-time'])]]['download']+=$ses[$i]['download'];
$reports[$tmpd[dateFormat($ses[$i]['from-time'])]]['upload']+=$ses[$i]['upload'];         
      }
      
      //------
      
  }
  $tmp=null;
  $tmpd=null;
  for($i=0;$i<count($arr);$i++)
  {
      for($j=0;$j<count($used);$j++)
      {
 if($arr[$i]['user']==$used[$j]['user'])
 {
$pay[$used[$j]['index']]['trans-start']=$arr[$i]['date'];
break;
 }
          
      }
      
  }
  
  
  
    

//$info[0]['date']=$date;
//$info[0]['download']=$download;
//$info[0]['upload']=$upload;


$a[0]['payment']=json_encode($pay);
$a[0]['users']=json_encode($users);
$a[0]['info']=json_encode($reports);

//echo "<pre>";
//print_r($users);

echo json_encode($a);


}




/*
include("login.php");
if($login)
{
    
    $users=$Mik->comm("/tool/user-manager/user/print");
$pay=$Mik->comm("/tool/user-manager/payment/print");
$ses=$Mik->comm("/tool/user-manager/session/print");
  //  $users=$usersm;
  $u=0;
    for($i=0;$i<count($users);$i++)
    {
if($users[$i]['id-sup']=="")
  {
      

$users[$i]['id-sup']="";
}
if($users[$i]['date-payment']=="")
  {
      

$users[$i]['date-payment']="";
}
        
        
if($users[$i]['date-first-login']=="")
  {
      

$users[$i]['date-first-login']="";
}
if($users[$i]['caller-id']=="")
  {
      
$users[$i]['caller-id']="";
  }
  
if($users[$i]['price']=="")
  {
      
$users[$i]['price']="";
  }
if($users[$i]['actual-profile']=="")
  {
      
$users[$i]['actual-profile']="";
  }
  
if($users[$i]['uptime-used']=="")
  {
      
$users[$i]['uptime-used']="";
  }
  
if($users[$i]['last-seen']!="never")
  {
      
//$users[$i]['last-seen']="";
$card[$u]['username']=$users[$i]['username'];
$card[$u]['index']=$i;
$u++;
  }
  
  

    
if($users[$i]['upload-used']=="")
  {
      
$users[$i]['upload-used']="";
  }
if($users[$i]['download-used']=="")
  {
      
$users[$i]['download-used']="";
  }
  
  
  
    for($j=0;$j<count($pay);$j++)
    {
        
     if($users[$i]['username']==$pay[$j]['user'])
        {
 $users[$i]['price']=$users[$i]['price'].",".(($pay[$j]['price'])/100);
 
 
 $users[$i]['id-sup']=$users[$i]['id-sup'].",".$pay[$j]['result-msg'];
$users[$i]['date-payment']=$users[$i]['date-payment'].",".$pay[$j]['trans-start'];


 

            
        }
    }
    
    
    }
    
    


    function index($str,$array)
    {
        
for($j=0;$j<count($array);$j++)
{
    if($str==$array[$j]['username'])
    {
        return $array[$j]['index'];
    }
    
}
return -1;
}
    
    $str1=null;

for($i=count($ses)-1;$i>=0;$i--)
{
    if($ses[$i]['user']!=$str1)
    {
     $str1= $ses[$i]['user'];
$index=index($str1,$card);
if($index!=-1)
{
     
$users[$index]['date-first-login']=$ses[$i]['from-time'];


}
    }

        
        
    
}


$jsonU=json_encode($users);
    

$jsonS=json_encode($ses);
    
    
    $arr[0]['users']=$jsonU;

   // $arr[0]['payment']=json_encode($pay);
   
//echo("<pre>");
   
    $arr[0]['session']=$jsonS;
  // echo json_encode($arr);
    
 // echo("<pre>");
 // print_r($users);
echo json_encode($arr);
}*/
?>