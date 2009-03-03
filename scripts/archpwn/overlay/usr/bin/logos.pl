## Put your distrobutions logos here
#
# Format::
#   For a new distro
#       push @distros, ["DistroShowName", "/path/to/current/version", "Optional regexp to get & append to the DistroShowName"];
#       $distroname = "..distros logo..";
#   
#   The logo variable should be a lower-cased version of the DistroShowName.
#   With in the logo, Please escape unused %.
# 
#


push @distros, ["ArchLinux", "/etc/issue", "Arch Linux \\((.*?)\\)"];
$archlinux = "
$colors[0]              __
$colors[0]          _=(SDGJT=_
$colors[0]        _GTDJHGGFCVS)                $colors[0]%s
$colors[0]       ,GTDJGGDTDFBGX0               $colors[0]%s
$colors[0]      JDJDIJHRORVFSBSVL$colors[1]-=+=,_        $colors[0]%s
$colors[0]     IJFDUFHJNXIXCDXDSV,$colors[1]  \"DEBL      $colors[0]%s
$colors[0]    [LKDSDJTDU=OUSCSBFLD.$colors[1]   '?ZWX,   $colors[0]%s
$colors[0]   ,LMDSDSWH'     \`DCBOSI$colors[1]     DRDS], $colors[0]%s
$colors[0]   SDDFDFH'         !YEWD,$colors[1]   )HDROD  $colors[0]%s
$colors[0]  !KMDOCG            &GSU|$colors[1]\_GFHRGO'   $colors[0]%s
$colors[0]  HKLSGP'$colors[1]           __$colors[0]\TKM0$colors[1]\GHRBV)'    $colors[0]%s
$colors[0] JSNRVW'$colors[1]       __+MNAEC$colors[0]\IOI,$colors[1]\BN'
$colors[0] HELK['$colors[1]    __,=OFFXCBGHC$colors[0]\FD)
$colors[0] ?KGHE $colors[1]\_-#DASDFLSV='$colors[0]    'EF
$colors[0] 'EHTI                   !H
$colors[0]  \`0F'                   '!
$nocolor";

