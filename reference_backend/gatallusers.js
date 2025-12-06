
:local json "";

:foreach i  in=[/tool user-manager user find] do={
    :local users [/tool user-manager user get $i];
:local count 0;
:foreach s in=[/tool user-manager session find where user=($users->"username")] do={
    if ($count=0) do={
        :set count 1;
        :local firstLogin [[/tool user-manager session get $s] from-time];
        
    };
    
    
    
};
:set json ($json."{\"username\":\""  .($users->"username")."\",");


    
};
:put $json;