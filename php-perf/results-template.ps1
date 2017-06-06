#%powershell1.0%
#
# File: results-template.ps1
# Description: Output $data into html table.  This script is meant to be called from summarize-results.ps1.
#

Function gaincalc ( $a=0, $b=0 )  {
	if ( ($a -ne 0) -and ($b -ne 0) )  {
		$c = ($a / $b) - 1

		switch ($c*100)  {
			{$_ -ge 0 -and $_ -le 3} {$script:gainclass="none"}
			{$_ -gt 3 -and $_ -le 7} {$script:gainclass="gainpossmall"}
			{$_ -ge 0 -and $_ -gt 7} {$script:gainclass="gainpos"}
			{$_ -lt 0 -and $_ -ge -3} {$script:gainclass="none"}
			{$_ -lt -3 -and $_ -ge -7} {$script:gainclass="gainnegsmall"}
			{$_ -lt 0 -and $_ -lt -7} {$script:gainclass="gainneg"}
			Default { $script:gainclass="none" }
		}

		"{0:P2}" -f $c
	}
	else  {
		$script:gainclass="none"
	}
}


write-output "

<html>
<head>
 <style type=text/css>
   .data td { border:1px solid black;white-space:nowrap; }
   .iis { background-color:#E6B8B7; }
   .iiswincache { background-color: #DA9694; }
   .apache { background-color: #C5D9F1; }
   .apachenoigbinary { background-color: #8DB4E2; }
   .apachewithigbinary { background-color: #538DD5; }
   .gainpos { background-color: #00A84C; }
   .gainpossmall { background-color: #00D661; }
   .gainneg { background-color: #FF2929; }
   .gainnegsmall { background-color: #DA9694; }
   a { font-size: 12px }
 </style>
 </head>

<body>
<table border=0 cellpadding=0 cellspacing=0 width=600>
<tr>
<td> <strong> PHP Performance </strong> </td> 
<td> <strong> Hardware & Environment </strong> </td>
</tr><tr>
<td>$PHP1 - $PHP2</td>
<td>Dell R710</td>
</tr><tr>
<td> &nbsp; </td>
<td>CPU - Intel Quad core @ 2.26Ghz (x2) L5520</td>
</tr><tr>
<td> &nbsp; </td>
<td>Memory - 12GB RAM</td>
</tr><tr>
<td> &nbsp; </td>
<td>HD - 147GB SAS RAID 1</td>
</tr><tr>
<td> &nbsp; </td>
<td>NIC - 1Gbps Intel</td>
</tr><tr>
<td> &nbsp; </td>
<td>Windows Server 2012</td>
</tr><tr>
<td> &nbsp; </td>
<td>php-web02.ctac.nttest.microsoft.com</td>
</tr>
</table>
<p> &nbsp; </p>

<table border=0 cellpadding=0 cellspacing=0 width=100% class=data>

<!-- Header Labels -->
 <tr>
  <td colspan=4></td>
  <td colspan=6 class=iis>IIS 7.5</td>
  <td colspan=9 class=apache>Apache 2.4</td>
 </tr>

 <tr>
  <td colspan=4></td>
  <td colspan=3 rowspan=2 class=iis>No Cache</td>
"
if ( $php1wincache -eq $php2wincache )  {
	write-output "
  <td colspan=3 rowspan=2 class=iiswincache>$php1wincache</td>
  <td colspan=3 rowspan=2 class=apache>No Cache</td>
  <td colspan=3 class=apachenoigbinary>$php1apachecache</td>
  <td colspan=3 class=apachenoigbinary>APC</td>
"
}  else  {
	write-output "
  <td colspan=1 rowspan=2 class=iiswincache>$php1wincache</td>
  <td colspan=2 rowspan=2 class=iiswincache>$php2wincache</td>
  <td colspan=3 rowspan=2 class=apache>No Cache</td>

  <td colspan=1 class=apachenoigbinary>$php1apachecache</td>
  <td colspan=2 class=apachenoigbinary>$php2apachecache</td>
  <td colspan=3 class=apachenoigbinary>APC</td>
"
}

write-output "
 </tr>
 <tr>
  <td></td>
  <td colspan=3>Load Agents</td>
  <td colspan=3 class=apachenoigbinary>-igbinary</td>
  <td colspan=3 class=apachewithigbinary>+igbinary</td>
 </tr>
 <!-- Header Labels -->

 <tr>
  <td>Application</td>
  <td>Physical</td>
  <td>Virtual</td>
  <td></td>

<!-- IIS No Cache -->

  <td>$PHP1</td>
  <td>$PHP2</td>
  <td>gain</td>

<!-- IIS Cache -->
  <td>$PHP1</td>
  <td>$PHP2</td>
  <td>gain</td>

<!-- Apache No Cache -->
  <td>$PHP1</td>
  <td>$PHP2</td>
  <td>gain</td>

<!-- Apache Cache -igbinary -->
  <td>$PHP1</td>
  <td>$PHP2</td>
  <td>gain</td>

<!-- Apache Cache +igbinary -->
  <td>$PHP1</td>
  <td>$PHP2</td>
   <td>gain</td>
 </tr>
 
<!-- Results --> 
"

Foreach ( $app in $appnames )  {
	## Notes: $data[App_Name][Apache|IIS][cache|nocache|cachenoigbinary|cachewithigbinary][php1|php2][ver|tps8|tps16|tps32]

	write-output "
 <tr>
  <td rowspan=3>$app</td>
	"

	Foreach ( $virt in $VIRTUAL )  {
		$gain = ""
		$gainclass = ""
		if ( $virt -ne "8" )  {
			write-output "<tr>"
		}

		write-output "
  <td>2</td>
  <td>$virt</td>
  <td>&nbsp;</td>

  <!-- IIS - No Cache -->
  <td class=iis>" $data[$app]["IIS"]["nocache"]["php1"]["tps$virt"] "</td>
  <td class=iis>" $data[$app]["IIS"]["nocache"]["php2"]["tps$virt"] "</td>"

		$gain = gaincalc $data[$app]["IIS"]["nocache"]["php2"]["tps$virt"] $data[$app]["IIS"]["nocache"]["php1"]["tps$virt"]
		write-output "

	<td class=$gainclass>&nbsp;$gain
  </td> <!-- Gain -->

  <!-- IIS - Cache -->
  <td class=iiswincache>" $data[$app]["IIS"]["cache"]["php1"]["tps$virt"] "</td>
  <td class=iiswincache>" $data[$app]["IIS"]["cache"]["php2"]["tps$virt"] "</td>"


		$gain = gaincalc $data[$app]["IIS"]["cache"]["php2"]["tps$virt"] $data[$app]["IIS"]["cache"]["php1"]["tps$virt"]
		write-output "

  <td class=$gainclass>&nbsp;$gain
  </td> <!-- Gain -->
  
  <!-- Apache - No Cache -->
  <td class=apache>" $data[$app]["Apache"]["nocache"]["php1"]["tps$virt"] "</td>
  <td class=apache>" $data[$app]["Apache"]["nocache"]["php2"]["tps$virt"] "</td>"
  
		$gain = gaincalc $data[$app]["Apache"]["nocache"]["php2"]["tps$virt"] $data[$app]["Apache"]["nocache"]["php1"]["tps$virt"]
		write-output "

  <td class=$gainclass>&nbsp;$gain
  </td> <!-- Gain -->

  <!-- Apache - Cache -igbinary -->
  <td class=apachenoigbinary>" $data[$app]["Apache"]["cachenoigbinary"]["php1"]["tps$virt"] "</td>
  <td class=apachenoigbinary>" $data[$app]["Apache"]["cachenoigbinary"]["php2"]["tps$virt"] "</td>"

		$gain = gaincalc $data[$app]["Apache"]["cachenoigbinary"]["php2"]["tps$virt"] $data[$app]["Apache"]["cachenoigbinary"]["php1"]["tps$virt"]
		write-output "
		
  <td class=$gainclass>&nbsp;$gain
  </td> <!-- Gain -->

  <!-- Apache - Cache +igbinary -->
  <td class=apachewithigbinary>" $data[$app]["Apache"]["cachewithigbinary"]["php1"]["tps$virt"] "</td>
  <td class=apachewithigbinary>" $data[$app]["Apache"]["cachewithigbinary"]["php2"]["tps$virt"] "</td>"
  
		$gain = gaincalc $data[$app]["Apache"]["cachewithigbinary"]["php2"]["tps$virt"] $data[$app]["Apache"]["cachewithigbinary"]["php1"]["tps$virt"]
		write-output "

  <td class=$gainclass>&nbsp;$gain
  </td> <!-- Gain -->
 </tr>
		"
	}  ## End Foreach
}  ## End Foreach

write-output "
</table>

<a href='https://github.com/OSTC/php-perf'>PHP-Perf Scripts</a> |
<a href='https://github.com/OSTC/php-perf/tree/master/conf/ini'>PHP Configuration Files</a> |
<a href='https://github.com/OSTC/php-perf/tree/master/conf'>WCAT Configuration</a>

<p> &nbsp; </p>
"

if ( $errlog -ne "" )  {
	write-output "<strong>Error Log</strong> - "
	write-output "<i>Requests that did not return a status 200 response will be counted here</i> <br/><br/>"
	write-output "$errlog"
}

write-output "
</body>
</html>
"

