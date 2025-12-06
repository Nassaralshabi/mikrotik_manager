<?php
include("login.php");
if($login)
{
    
    $customer=$Mik->comm("/tool/user-manager/customer/print");
    echo json_encode($customer);
}
?>