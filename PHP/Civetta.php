<?php
class foo {

	function foo(){
	// construct
	}

	function bar(){
	$this = true;  //VIOLAZ
	}
a=a;
if (a==a) {
			}
ini_set('memory_limit', '1024M'); //unknown why we ever experience this
require_once 'config2.php';

$Email = "testsr@gmail.com";
$Path = "c:\test\file.xml";
$$var = 'bar';      //VIOLAZ 
$$$var = 'hello';  //VIOLAZ

var pippo;

setlocale(LC_ALL, "ita", 'it_IT');

require '../vendor/autoload.php';
// Include the main Propel script c:\test\file.xml
require_once '../vendor/propel/propel1/runtime/lib/Propel.php'; require_once '../vendor/propel/propel1/runtime/lib/Propel.php'; require_once '../vendor/propel/propel1/runtime/lib/Propel.php'; require_once '../vendor/propel/propel1/runtime/lib/Propel.php';

// Initialize Propel with the runtime configuration
Propel::init("../build/conf/postetracker-conf.php");
// Add the generated 'classes' directory to the include path
set_include_path("../build/classes" . PATH_SEPARATOR . get_include_path());

$con = Propel::getConnection(MailingPeer::DATABASE_NAME);
$con->exec("set names utf8");
$con->useDebug(false);
//unknown why we ever experience this

$cache = TRUE;

$title = "Report";

$filename = $_GET["filename"];
include $filename . ".php";  //VIOLAZ

$filename = getenv('INCLUDE01');
include $filename . ".php"; //VIOLAZ
$filename = $_GET["filename"];

myGlobalVariable;
class Foo {
    public function bar($param)  {
        if ($param === 42) {
            exit(23); //violaz
			extract($x); //violaz
			extract();
			if (a==a) {
			}
        }
    }
}
function foo()
{
  global $myGlobalVariable; // VIOLAZ
  $GLOBALS['myGlobalVariable']; // VIOLAZ
  require_once('./modules/vegetable/src/Entity/Tomato.php');
  if (php_sapi_name() == 'test') { ... } // VIOLAZ
	if (PHP_SAPI == 'test') { ... } // OK
	ereg();
	
	try {
		echo inverse(5) . "\n";
	} catch (Exception $e) {
		echo 'Caught exception: ',  $e->getMessage(), "\n";
	} finally {
	echo "First finally.\n";
	}
	
	try {
		try {
		}
		
	} catch (Exception $e) {
		
	} finally {
	
	}
	
  // ...
}

if (in_array($filename, $whitelist)) {
  include $filename . ".php";  // OK, è dentro una if
  myfun(&$name);  // VIOLAZ
  
	switch ($param) {
		case 0:
			if (a==a) {
			}
		case 1:
	}
	  switch ($param) {
	  case 0:
		doSomething();
		$take_vacation = $have_time and $have_money;  // VIOLAZ
		$take_vacation = $have_time && $have_money;  // OK
		break;
	  default: // VIOLAZ
		error();
		break;
	  case 1:
		doSomethingElse();
		break;
	}

	  switch ($param) {
	  case 0:
		doSomething();
		break;
	  default: // VIOLAZ
		error();
		switch ($param) {
			case 0:
				doSomethingElse();
				break;
			default:
				error();
				break;
		}
		break;
	  case 1:
		doSomethingElse();
		break;
	}
	
}

function getMonth($m)
{
    switch ($m) {
        case "1":
            return "Gennaio";
        case "2":
            return "Febbraio";
        case "3":
            return "Marzo";
        case "4":
            return "Aprile";
        case "5":
            return "Maggio";
        case "6":
            return "Giugno";
        case "7":
            return "Luglio";
        case "8":
            return "Agosto";
        case "9":
            return "Settembre";
        case "10":
            return "Ottobre";
        case "11":
            return "Novembre";
        case "12":
            return "Dicembre";
    }
}

function fatal_handler()
{
    $errfile = "unknown file";
    $errstr = "shutdown";
    $errno = E_CORE_ERROR;
    $errline = 0;

    $error = error_get_last();

    if ($error !== NULL) {
        $errno = $error["type"];
        $errfile = $error["file"];
		goto pippo;

        $errline = $error["line"];
        $errstr = $error["message"];
pippo:
        Propel::log($errno . "|" . $errstr . ", file: " . $errfile . " on line " . $errline, Propel::LOG_ERR);
    }
}

register_shutdown_function("fatal_handler");

Propel::log("[REPORT_MAKER] ", Propel::LOG_INFO);


// naz, naz_mon, int, int_mon, naz_all, int_all
$type = $argv[1];

$period = isset($argv[2]) ? $argv[2] : "YTD";

// ALT, se vuoto non viene applicato il filtro
$alt = isset($argv[3]) ? str_replace("_", " ", $argv[3]) : FALSE;

$preview = FALSE;
if ($alt === "PREVIEW") {
    $alt = FALSE;
    $templatePath = $templatePreviewPath;
    $outputPath = $previewPath;
    $preview = TRUE;

    $title = "[PREVIEW] " . $title;
}
if (isset($argv[4]) && $argv[4] === "PREVIEW") {
    $templatePath = $templatePreviewPath;
    $outputPath = $previewPath;
    $preview = TRUE;
    $title = "[PREVIEW] " . $title;
}

$yesterday = new DateTime();
if (!$preview) $yesterday->modify("yesterday");
if ($yesterday->format("D") == "Sat" || $yesterday->format("D") == "Sun") {
    $yesterday->modify("yesterday");
}
if ($yesterday->format("D") == "Sat" || $yesterday->format("D") == "Sun") {
    $yesterday->modify("yesterday");
}

switch ($period) {
    case "OLDYTD":
        $today = new DateTime();
        if ((int)$today->format("Y") < 2015) {
            echo "Il report del vecchio anno viene generato solo dal 2015 in poi...";
            exit;
        }

        if ((int)$today->format("m") > 2) {
            echo "Dopo il mese di febbraio, il report del vecchio anno non viene piu' calcolato.";
            exit;
        }
        // First day of year
        $startDate = new DateTime();
        $startDate->modify("first day of January previous year");

        $endDate = new DateTime();
        $endDate->modify("last day of December previous year");

        $year = $startDate->format("Y");
        $prefix = "YTD";
        $title .= " YTD";

        break;

    case "YTD":
        // First day of year
        $firstDayOfYear = new DateTime("first day of January 2016");
        $firstDayOfYear->setDate($firstDayOfYear->format("Y"), 1, 1);

        $startDate = $firstDayOfYear;
        $endDate = new DateTime("last day of December 2016");
        $year = $startDate->format("Y");
        $prefix = "YTD";
        $title .= " YTD";

        break;

    case "MONTHLY":
        //$startDate = new DateTime("first day of last month");
        $startDate = new DateTime("first day of January 2016");
        //var_dump($startDate);
        //$endDate = new DateTime("last day of last month");
        $endDate = new DateTime("last day of January 2016");
        //var_dump($endDate);
        $year = $startDate->format("Y");
        $prefix = getMonth($startDate->format("n"));
        $title .= " " . getMonth($startDate->format("n"));
        break;

    case "CMONTHLY":
        //$startDate = new DateTime("first day of this month");
        $startDate = new DateTime("first day of February 2016");
        //$endDate = $yesterday;
        $endDate = new DateTime("last day of February 2016");
        if ($endDate->format('m') < $startDate->format('m')) {
            $startDate->modify('first day of last month');
        }
        $year = $startDate->format("Y");
        $prefix = getMonth($startDate->format("n"));
        $title .= " " . getMonth($startDate->format("n"));
        break;

    case "OLDMONTHLY":
        //$startDate = new DateTime("first day of last month");
        //$startDate->modify("first day of previous month");
        $startDate = new DateTime("first day of March 2016");
        //$endDate = new DateTime("last day of last month");
        //$endDate->modify("last day of previous month");
        $endDate = new DateTime("last day of March 2016");
        $year = $startDate->format("Y");
        $prefix = getMonth($startDate->format("n"));
        $title .= " " . getMonth($startDate->format("n"));
        break;
}


switch ($type) {
    case "naz_all":
        $template = $templatePath . "Analisi_temp.xls";
        $output = $outputPath . "Diagnostico/Prioritario Nazionale/$year/$prefix/Report_{$prefix}_PP_Nazionale_Missing.xls";
        $mailingType = 1;
        $title .= " Nazionale Missing - Solo Analisi";
        break;

    case "naz":
        if ($alt) {
            $template = $templatePath . "{$alt}_Report_YTD_PP_Nazionale_temp.xls";
            $output = $outputPath . "ALT/$alt/Prioritario Nazionale/$year/$prefix/Report_{$alt}_{$prefix}_PP_Nazionale.xls";
        } else {
            if ($prefix == "YTD") $cache = FALSE;
            $template = $templatePath . "Report_YTD_PP_Nazionale_temp.xls";
            $output = $outputPath . "Diagnostico/Prioritario Nazionale/$year/$prefix/Report_{$prefix}_PP_Nazionale.xls";
        }
        $mailingType = 1;
        $title .= " Nazionale";
        break;

    case "naz_mon":
        if ($alt) {
            $template = $templatePath . "{$alt}_Report_YTD_PP_Diagn_Monitor_Nazionale_temp.xls";
            $output = $outputPath . "ALT/$alt/Prioritario Nazionale/$year/$prefix/Report_{$alt}_{$prefix}_PP_Monitor_Nazionale.xls";
        } else {
            $template = $templatePath . "Report_YTD_PP_Diagn_Monitor_Nazionale_temp.xls";
            $output = $outputPath . "Diagnostico/Prioritario Nazionale/$year/$prefix/Report_{$prefix}_PP_Monitor_Nazionale.xls";
        }
        $mailingType = 1;
        $title .= " Nazionale Monitor";
        break;

    case "naz_iucd":
        //if ($alt) {
        //$template = $templatePath . "{$alt}_Report_Ingresso_Uscita_CD_Nazionale_temp.xls";
        // $output = $outputPath . "ALT/$alt/Prioritario Nazionale/$year/$prefix/Report_{$alt}_{$prefix}_Ingresso_Uscita_CD_Nazionale.xls";
        //} else {
        $template = $templatePath . "Report_Ingresso_Uscita_CD_Nazionale_temp.xls";
        $output = $outputPath . "Diagnostico/Prioritario Nazionale/$year/$prefix/Report_{$prefix}_Ingresso_Uscita_CD_Nazionale.xls";
        //}
        $mailingType = 1;
        $title .= " Ingresso_Uscita CD Nazionale";
        break;

    case "int_all":
        $template = $templatePath . "Analisi_temp.xls";
        $output = $outputPath . "Diagnostico/Prioritario Internazionale/$year/$prefix/Report_{$prefix}_PP_Internazionale_Missing.xls";
        $mailingType = 2;
        $title .= " Internazionale Missing - Solo Analisi";
        break;

    case "int":
        if ($alt) {
            $template = $templatePath . "{$alt}_Report_YTD_PP_Internazionale_temp.xls";
            $output = $outputPath . "ALT/$alt/Prioritario Internazionale/$year/$prefix/Report_{$alt}_{$prefix}_PP_Internazionale.xls";
        } else {
            if ($prefix == "YTD") $cache = FALSE;
            $template = $templatePath . "Report_YTD_PP_Internazionale_temp.xls";
            $output = $outputPath . "Diagnostico/Prioritario Internazionale/$year/$prefix/Report_{$prefix}_PP_Internazionale.xls";
        }
        $mailingType = 2;
        $title .= " Internazionale";
        break;

    case "int_mon":
        if ($alt) {
            $template = $templatePath . "{$alt}_Report_YTD_PP_Diagn_Monitor_Internazionale_temp.xls";
            $output = $outputPath . "ALT/$alt/Prioritario Internazionale/$year/$prefix/Report_{$alt}_{$prefix}_PP_Monitor_Internazionale.xls";
        } else {
            $template = $templatePath . "Report_YTD_PP_Diagn_Monitor_Internazionale_temp.xls";
            $output = $outputPath . "Diagnostico/Prioritario Internazionale/$year/$prefix/Report_{$prefix}_PP_Monitor_Internazionale.xls";
        }
        $mailingType = 2;
        $title .= " Internazionale Monitor";
        break;

    case "int_iucd":
//        if ($alt) {
//            $template = $templatePath . "{$alt}_Report_Ingresso_Uscita_CD_Internazionale.xls";
//            $output = $outputPath . "ALT/$alt/Prioritario Internazionale/$year/$prefix/Report_{$alt}_{$prefix}_Ingresso_Uscita_CD_Internazionale.xls";
//        } else {
        $template = $templatePath . "Report_Ingresso_Uscita_CD_Internazionale_temp.xls";
        $output = $outputPath . "Diagnostico/Prioritario Internazionale/$year/$prefix/Report_{$prefix}_Ingresso_Uscita_CD_Internazionale.xls";
//        }
        $mailingType = 2;
        $title .= " Ingresso_Uscita CD Internazionale";
        break;

    default:
        echo "Type $type is invalid.\n";
        exit;
}
echo "Start date: " . $startDate->format("d/m/Y") . "\n";
echo "End date: " . $endDate->format("d/m/Y") . "\n";

// Nel weekend non recupero nuovi record
$today = new DateTime();
$weekend = $today->format("D") == "Sat" || $today->format("D") == "Sun";

$previewWhere = "";
if ($preview == FALSE || $weekend) $previewWhere = "preview = 1 AND";

if ($type == "naz_all" || $type == "int_all") {
    echo "\nSolo Analisi\n";
    $q = \MailingQuery::create()
        ->where("mailing_type_id = $mailingType AND enabled = 1 AND "
            . "(last_scan >= '{$startDate->format("Y-m-d")}' AND (last_scan <= '{$endDate->format("Y-m-d")}' OR last_scan > '{$endDate->format("Y-m-d")}')) OR "
            . "(last_scan IS NULL AND sending_date >= '{$startDate->format("Y-m-d")}' AND sending_date <= '{$endDate->format("Y-m-d")}')")
        ->orderBy("sending_date", \Criteria::ASC)
        ->find();

} else {
    if ($period == "YTD") {
        /*$q = \MailingQuery::create()
                ->where("receiving_date IS NOT NULL AND mailing_type_id = $mailingType AND enabled = 1 AND $previewWhere "
                        . "((sending_date >= '{$startDate->format("Y-m-d")}' AND sending_date <= '{$endDate->format("Y-m-d")}') "
                        . "OR "
                        . "(receiving_date >= '{$startDate->format("Y-m-d")}' AND receiving_date <= '{$endDate->format("Y-m-d")}'))")
                ->orderBy("sending_date", \Criteria::ASC)
                ->find();*/
        $q = \MailingQuery::create()
            ->where("(receiving_date IS NOT NULL OR unknown_receiving_date = 1) AND mailing_type_id = $mailingType AND enabled = 1 AND $previewWhere "
                . "((sending_date >= '{$startDate->format("Y-m-d")}' AND sending_date <= '{$endDate->format("Y-m-d")}') "
                . "OR "
                . "(last_scan >= '{$startDate->format("Y-m-d")}' AND last_scan <= '{$endDate->format("Y-m-d")}'))")
            ->orderBy("sending_date", \Criteria::ASC)
            ->find();
    } else {
        $q = \MailingQuery::create()
            ->where("(receiving_date IS NOT NULL OR unknown_receiving_date = 1) AND mailing_type_id = $mailingType AND enabled = 1 AND $previewWhere "
                . "last_scan >= '{$startDate->format("Y-m-d")}' AND last_scan <= '{$endDate->format("Y-m-d")}'")
            ->orderBy("sending_date", \Criteria::ASC)
            ->find();
        /*$q = \MailingQuery::create()
            ->where("receiving_date IS NOT NULL AND mailing_type_id = $mailingType AND enabled = 1 AND $previewWhere "
                . "(receiving_date >= '{$startDate->format("Y-m-d")}' AND receiving_date <= '{$endDate->format("Y-m-d")}')")
             ->orderBy("sending_date", \Criteria::ASC)
                    ->find();*/
    }

}

echo "Mailing found: " . $q->count() . "\n";

if ($q->count() == 0) {
    echo "Exit without actions.\n";
    exit;
}

/*
 * Nazionale/Internazionale (in comune)
 *
 * 0 Mail ID
 * 1 Transponder ID
 * 2 Link
 * 3 CAP di Spedizione
 * 4 CAP di Ricezione
 * 5 Data di Spedizione
 * 6 Orario di Spedizione
 * 7 Orario di Ultimo Ritiro
 * 8 Data Timbro di Spedizione
 * 9 On Time
 * 10 Centro di Ripartizione in Partenza (CRP)
 * 11 Centro di Ripartizione in Arrivo (CRA)
 * 12 Centro Postale (CP)
 * 13 CD
 * 14 Prima Lettura CRP (o CSI nel caso del Monitor Internazionale)
 * 15 Ultima Lettura CRP (o CSI nel caso del Monitor Internazionale)
 * 16 Prima Lettura CRA
 * 17 Ultima Lettura CRA
 * 18 Prima Lettura CP
 * 19 Ultima Lettura CP
 * 20 Prima Lettura CD
 * 21 Ultima Lettura CD
 *
 * 22 On-Time Raccolta
 * 23 On-Time Lavorazione CRP
 * 24 On-Time Trasporto di CRA
 * 25 On-Time Lavorazione CRA
 * 26 On-Time Trasporto verso CP
 * 27 On-Time Lavorazione CP
 * 28 On-Time Trasporto verso CD
 * 29 On-Time Recapito
 * 30 Antenna in CD Esiste
 * 31 Prima Lettura in CD Esiste
 * 32 Ultima Lettura in CD Esiste
 * 33 Letture in CD
 *  */

/*
 * Nazionale Monitor EXTRA
 *
 * 34 Regione in Partenza [CRP]
 * 35 Regione in Arrivo [CD]
 * 36 [NO TITLE] GUASTO CRP
 * 37 [NO TITLE] GUASTO CRA
 * 38 [NO TITLE] GUASTO CP
 * 39 [NO TITLE] GUASTO CD
 */

/*
 * Internazionale Monitor EXTRA
 * 34 Citta del Ricevente
 * 35 Ufficio Postale del Ricevente
 * 36 J+1
 * 37 J+2
 * 38 J+3
 * 39 J+4
 * 40 Mail Delivery Days
 * 41 On Time - E2E
 * 42 J+1 - E2E
 * 43 J+2 - E2E
 * 44 J+3 - E2E
 * 45 J+4 - E2E
 * 46 Mail Delivery Days - E2E
 * 47 Regione in Partenza [CRP]
 * 48 Regione in Arrivo [CD]
 * 49 [NO TITLE] GUASTO CRP
 * 50 [NO TITLE] GUASTO CRA
 * 51 [NO TITLE] GUASTO CP
 * 52 [NO TITLE] GUASTO CD
 */

/*
 * Nazionale/Internazionale EXTRA
 *
 * 34 Ultima Lettura in CD > 11:30
 * 35 Data di Ricezione - E2E [DA IGNORARE]
 * 36 On-Time - E2E  [DA IGNORARE]
 * 37 Regione in Partenza [CRP]
 * 38 Regione in Arrivo [CD]
 * 39 [NO TITLE] ALT [CD]
 * 40 [NO TITLE] RAM [CD]
 * 41 [NO TITLE] CITTA' [CD]
 */

$eb = new \ExcelBook("SCENARI SRL  SCENARI SRL ", "linux-ebd512779da5a9160b03273d46oee9s3");
if (!$eb->loadFile($template)) {
    echo "Unable to load excel file.\n";
    exit;
}
$eb->setLocale('UTF-8');
$notWorkingStations = array();

function writeNotWorkingStations($sheet, &$names, $type)
{
    global $notWorkingStations, $endDate, $eb;
    $formats2 = array();
    if ($sheet) {
        for ($i = 0; $i < 100; $i++) {
            $formats2[$i] = $sheet->cellFormat(3, $i);
        }

        $sheet->clear(3, 1000, 3, 12);
    }
    // Popolo i fogli dei centri non funzionanti.
    $row = 3;
    foreach ($names as $fullname) {
        $s = \StationMasterdataQuery::create()
            ->filterByFullname($fullname)
            ->filterByStationTypeId($type)
            ->findOne();
        if (!$s) {
            echo "Station $fullname (type $type) not found.\n";
            $row++;
            continue;
        }
        $nwss = \NotWorkingStationsQuery::create()
            //@todo filtrare per il periodo del report?
            ->filterByStationMasterdata($s)
            ->find();
        $col = 3;
        /*@var $nws \NotWorkingStations*/
        foreach ($nwss as $nws) {
            $date = $nws->getStartDate(NULL);

            if ($sheet) $sheet->write($row, $col, $eb->packDate($date->getTimestamp()), $formats2[$col], \ExcelFormat::AS_DATE);
            $ed = $nws->getEndDate(NULL);
            if (!$ed) $ed = $endDate;
            if ($sheet) $sheet->write($row, $col + 1, $eb->packDate($ed->getTimestamp()), $formats2[$col + 1], \ExcelFormat::AS_DATE);


            $col += 2;
            if ($col > 12) break;
        }

        $notWorkingStations[$s->getId()] = $col - 3;

        $row++;
    }
}

switch ($type) {
    case "int_mon":
    case "naz_mon":
        writeNotWorkingStations($eb->getSheetByName("Non Funzionante CD"), $nonFunzionanteCD, 3);
        writeNotWorkingStations($eb->getSheetByName("Non Funzionante CMP"), $nonFunzionanteCMP, 1);
        writeNotWorkingStations($eb->getSheetByName("Non Funzionante CP"), $nonFunzionanteCP, 2);
        break;

    case "int_iucd":
    case "naz_iucd":
        writeNotWorkingStations(FALSE, $nonFunzionanteCD, 3);
        writeNotWorkingStations(FALSE, $nonFunzionanteCMP, 1);
        writeNotWorkingStations(FALSE, $nonFunzionanteCP, 2);
        break;
}

$sheet = $eb->getSheetByName("Analisi");

$formats = array();
for ($i = 0; $i < 100; $i++) {
    $formats[$i] = $sheet->cellFormat(3, $i);
}
$sheet->clear(3, 6000, 0, 100);

$sheet->write(1, 0, "Analisi dal {$startDate->format("d/m/Y")} al {$endDate->format("d/m/Y")}");
$sheet->write(1, 1, "{$startDate->format("d/m/Y")}");
$sheet->write(1, 2, "{$endDate->format("d/m/Y")}");

/* @var $mail \Mailing */
$row = 3;
$errorMsg = array();
$warningMsg = array();
global $mailIdConsolidate;
foreach ($q as $mail) {
    $ai = new \Poste\AI($mail->getId());
    // Recupero la mailing
    $ret = $ai->process($cache);
    $skip = false;
    switch ((int)$ret) {
        case \Poste\AI::ERR_MAILING_NOT_FOUND:
        case \Poste\AI::ERR_SENDING_DATE_NOT_FOUND:
        case \Poste\AI::ERR_CP_AS_CRP:
        case \Poste\AI::ERR_NO_TRANSPONDER:
        case \Poste\AI::ERR_CRA_NOT_FOUND:
        case \Poste\AI::ERR_CUSTOM_REQUEST:
        case \Poste\AI::ERR_INTERNAL:
            $skip = TRUE;
    }

    if ($skip) {
        $errorMsg[] = $ai->errorsMsg;
        $warningMsg[] = $ai->warningMsg;
        continue;
    }


    $CRP = $ai->getStation("CRP");
    $CRA = $ai->getStation("CRA");
    $CP = $ai->getStation("CP");
    $CD = $ai->getStation("CD");

    if ($alt) {
        $pass = FALSE;
        if ($CRP && strcasecmp($CRP['station']->Alt, $alt) == 0) {
            $pass = TRUE;
        } else if ($ai->getDefaultCRP() && strcasecmp($ai->getDefaultCRP()->Alt, $alt) == 0) {
            $pass = TRUE;
        }

        if ($CRA && strcasecmp($CRA['station']->Alt, $alt) == 0) {
            $pass = TRUE;
        } else if ($ai->getDefaultCRA() && strcasecmp($ai->getDefaultCRA()->Alt, $alt) == 0) {
            $pass = TRUE;
        }
        if ($CP && strcasecmp($CP['station']->Alt, $alt) == 0) {
            $pass = TRUE;
        } else if ($ai->getDefaultCP() && strcasecmp($ai->getDefaultCP()->Alt, $alt) == 0) {
            $pass = TRUE;
        }
        if ($CD && strcasecmp($CD['station']->Alt, $alt) == 0) {
            $pass = TRUE;
        } else if ($ai->getDefaultCD() && strcasecmp($ai->getDefaultCD()->Alt, $alt) == 0) {
            $pass = TRUE;
        }

        if (!$pass) continue;
    }

    $o = $ai->getOutput();
    if (count($o) == 0) {
        echo "\n" . $mail->getMailId() . "\n";
        continue;
    }
    $sendingDate = $ai->getSendingDate();
    $sendingHour = $ai->getSendingHour();

    $date = $mail->getMailingPost(NULL);
    $pbt = $ai->getPBT();
    $link = preg_replace('/\s+/', '', $mail->getLink());
    $link = strtoupper($link);

    write($row, 0, $mail->getMailid(), $sheet->cellFormat(3, 0));
    write($row, 1, $mail->getTransponder()->getTagId(), $sheet->cellFormat(3, 1));
    write($row, 2, $link, $sheet->cellFormat(3, 2));
    write($row, 3, $mail->getSendingCap(), $sheet->cellFormat(3, 3));
    write($row, 4, $mail->getReceiver()->getLivingCap(), $sheet->cellFormat(3, 4));
    write($row, 5, $eb->packDate($sendingDate->getTimestamp()), $sheet->cellFormat(3, 5), \ExcelFormat::AS_DATE);
    if ($sendingHour != null)
        write($row, 6, $sendingHour->format("H:i"), $sheet->cellFormat(3, 6));
    if ($pbt != null)
        write($row, 7, $pbt->format("H:i"), $sheet->cellFormat(3, 7));
    if ($date) {
        write($row, 8, $eb->packDate($date->getTimestamp()), $sheet->cellFormat(3, 8), \ExcelFormat::AS_DATE);
    } else {
        write($row, 8, "", $sheet->cellFormat(3, 8));
    }
    //MODIFICA INTRODOTTA PER LA VARIAZIONE DELLO SLA DEL CMP DI PALERMO(2 gg. lavorativi)
    //Non posso modificare l'algoritmo creando un caso specifico per palermo, per cui i test extrabacino da e per Palermo
    //sono contrassegnati con on-time = 3
    if(strtotime($mail->getSendingDate('Y-m-d H:i:s')) >= strtotime('2015-10-05 00:00:00')
        && (((!empty($CRP) && $CRP['station']->Country == "Sicilia") && (!empty($CRA) && $CRA['station']->Country != "Sicilia"))
            || ((!empty($CRP) && $CRP['station']->Country != "Sicilia") && (!empty($CRA) && $CRA['station']->Country == "Sicilia")))
        && ((!empty($CRP) && $CRP['station']->Fullname == "Palermo" && !empty($CRA) && $CRA['station']->Fullname != 'Palermo')
            || (!empty($CRA) && $CRA['station']->Fullname == "Palermo" && !empty($CRP) && $CRP['station']->Fullname != 'Palermo'))) {
        write($row, 9, 3, $sheet->cellFormat(3, 9));
    } else {
        write($row, 9, $ai->getOnTime(), $sheet->cellFormat(3, 9));
    }

    if ($CRP) {
        write($row, 10, $CRP['station']->Fullname, $sheet->cellFormat(3, 10));
        write($row, 14, parseStationDate($CRP['in']), $sheet->cellFormat(3, 14));
        write($row, 15, parseStationDate($CRP['out']), $sheet->cellFormat(3, 15));
    } else if ($ai->getDefaultCRP()) {
        write($row, 10, $ai->getDefaultCRP()->Fullname);
    }

    if ($CRA) {
        write($row, 11, $CRA['station']->Fullname, $sheet->cellFormat(3, 11));
        write($row, 16, parseStationDate($CRA['in']), $sheet->cellFormat(3, 16));
        write($row, 17, parseStationDate($CRA['out']), $sheet->cellFormat(3, 17));
    } else if ($ai->getDefaultCRA()) {
        write($row, 11, $ai->getDefaultCRA()->Fullname);
    }

    if ($CP) {
        write($row, 12, $CP['station']->Fullname, $sheet->cellFormat(3, 12));
        write($row, 18, parseStationDate($CP['in']), $sheet->cellFormat(3, 18));
        write($row, 19, parseStationDate($CP['out']), $sheet->cellFormat(3, 19));
    } else if ($ai->getDefaultCP()) {
        write($row, 12, $ai->getDefaultCP()->Fullname);
    }

    if ($CD) {
        $in = parseStationDate($CD['in']);
        $out = parseStationDate($CD['out']);

        write($row, 13, $CD['station']->Fullname, $sheet->cellFormat(3, 13));
        write($row, 20, $in, $sheet->cellFormat(3, 20));
        write($row, 21, $out, $sheet->cellFormat(3, 21));
        write($row, 31, $in != "" ? 1 : 0, $sheet->cellFormat(3, 31));
        write($row, 32, $out != "" ? 1 : 0, $sheet->cellFormat(3, 32));
        write($row, 33, ($in != "" || $out != "") ? 1 : 0, $sheet->cellFormat(3, 33));
    } else if ($ai->getDefaultCD()) {
        write($row, 13, $ai->getDefaultCD()->Fullname, $sheet->cellFormat(3, 13));
    }

    write($row, 22, $ai->getOnTimeStep(0, 0), $sheet->cellFormat(3, 22));
    write($row, 23, $ai->getOnTimeStep(0, 1), $sheet->cellFormat(3, 23));
    write($row, 24, $ai->getOnTimeStep(1, 0), $sheet->cellFormat(3, 24));
    write($row, 25, $ai->getOnTimeStep(1, 1), $sheet->cellFormat(3, 25));
    write($row, 26, $ai->getOnTimeStep(2, 0), $sheet->cellFormat(3, 26));
    write($row, 27, $ai->getOnTimeStep(2, 1), $sheet->cellFormat(3, 27));
    write($row, 28, $ai->getOnTimeStep(3, 0), $sheet->cellFormat(3, 28));
    write($row, 29, $ai->getOnTimeStep(3, 1), $sheet->cellFormat(3, 29));

    write($row, 30, 1, $sheet->cellFormat(3, 30));

    // Pezzotto temporaneo: quando viene generato il foglio di analisi del
    // template Internazionale per ALT, viene TEMPORANEAMENTE? utilizzato il modello
    // dati del foglio di analisi del template Nazionale per ALT.

    // if ($alt && $type === "int_mon") $type = "naz_mon";

    switch ($type) {
        case "int_all":
        case "naz_all":
        case "int":
        case "naz":
            if ($CD) {
                $limit = FALSE;
                if ($CD['out']) {
                    /* @var $limit \DateTime */
                    $limit = clone $CD['out'];
                    $limit->setTime(11, 30, 00);
                }

                write($row, 34, ($limit && $CD['out'] > $limit) ? 1 : 0);
                $cds = $CD['station'];
            } else {
                $cds = $ai->getDefaultCD();
            }

            write($row, 35, $mail->getReceivingDate("%d/%m/%Y"));
            write($row, 36, $ai->getOnTime() === 1 ? 1 : 0);// 36 On-Time - E2E [DA IGNORARE]

            if ($cds) {
                write($row, 38, $cds->Country);

                write($row, 39, $cds->Alt);
                write($row, 40, $cds->Alt . " RAM-" . $cds->Ram);
                write($row, 41, $cds->City);
            }
            if ($CRP) {
                write($row, 37, $CRP['station']->Country);
            } else if ($ai->getDefaultCRP()) {
                write($row, 37, $ai->getDefaultCRP()->Country);
            }

            break;

        case "naz_iucd":
        case "naz_mon":
            if ($CRP) {
                write($row, 34, $CRP['station']->Country);
            } else if ($ai->getDefaultCRP()) {
                write($row, 34, $ai->getDefaultCRP()->Country);
            }

            if ($CD) {
                write($row, 35, $CD['station']->Country);
            } else if ($ai->getDefaultCD()) {
                write($row, 35, $ai->getDefaultCD()->Country);
            }

            if ($CRP) write($row, 36, $notWorkingStations[$CRP['station']->Id]);
            else if ($ai->getDefaultCRP()) write($row, 36, $notWorkingStations[$ai->getDefaultCRP()->Id]);

            if ($CRA) write($row, 37, $notWorkingStations[$CRA['station']->Id]);
            else if ($ai->getDefaultCRA()) write($row, 37, $notWorkingStations[$ai->getDefaultCRA()->Id]);

            if ($CP) write($row, 38, $notWorkingStations[$CP['station']->Id]);
            else if ($ai->getDefaultCP()) write($row, 38, $notWorkingStations[$ai->getDefaultCP()->Id]);

            if (!empty($CD)) {
                if (!empty($notWorkingStations[$CD['station']->Id]))
                    write($row, 39, $notWorkingStations[$CD['station']->Id]);
            } else if ($ai->getDefaultCD() != null) {
                if (!empty($notWorkingStations[$ai->getDefaultCD()->Id]))
                    write($row, 39, $notWorkingStations[$ai->getDefaultCD()->Id]);
            }

            break;

        case "int_iucd":
        case "int_mon":
            $receiverCity = $ai->getReceiverCity();
            $receiverCity = explode("(", $receiverCity);
            $receiverCity = trim($receiverCity[0]);

            write($row, 34, $receiverCity);
            write($row, 35, "");
            write($row, 36, $ai->getOnTime() === 1 ? 1 : 0);// 36 On-Time - E2E [DA IGNORARE]
            write($row, 37, 1);
            write($row, 38, 1);
            write($row, 39, 1);
            write($row, 40, $ai->getOnTime() === 1 ? 1 : ($ai->getOnTime() === 0 ? 2 : ''));

            write($row, 41, 1);
            write($row, 42, 1);
            write($row, 43, 1);
            write($row, 44, 1);
            write($row, 45, 1);
            write($row, 46, 1);

            if ($CRP) {
                write($row, 47, $CRP['station']->Country);
            } else if ($ai->getDefaultCRP()) {
                write($row, 47, $ai->getDefaultCRP()->Country);
            }

            if ($CD) {
                write($row, 48, $CD['station']->Country);
            } else if ($ai->getDefaultCD()) {
                write($row, 48, $ai->getDefaultCD()->Country);
            }

            if ($CRP) write($row, 49, $notWorkingStations[$CRP['station']->Id]);
            else if ($ai->getDefaultCRP()) write($row, 49, $notWorkingStations[$ai->getDefaultCRP()->Id]);

            if ($CRA) write($row, 50, $notWorkingStations[$CRA['station']->Id]);
            else if ($ai->getDefaultCRA()) write($row, 50, $notWorkingStations[$ai->getDefaultCRA()->Id]);

            if ($CP) write($row, 51, $notWorkingStations[$CP['station']->Id]);
            else if ($ai->getDefaultCP()) write($row, 51, $notWorkingStations[$ai->getDefaultCP()->Id]);

            if (!empty($CD)) {
                if (!empty($notWorkingStations[$CD['station']->Id]))
                    write($row, 52, $notWorkingStations[$CD['station']->Id]);
            } else if ($ai->getDefaultCD() != null) {
                if (!empty($notWorkingStations[$ai->getDefaultCD()->Id]))
                    write($row, 52, $notWorkingStations[$ai->getDefaultCD()->Id]);
            }
            break;
    }
    //calcolo on-time E2E
    if ($type == 'int' || $type == 'naz') {
        $dataRicezioneSconosciuta = $mail->getUnknownReceivingDate();
        $dataRicezione = $mail->getReceivingDate('Y-m-d');
        if (!empty($dataRicezioneSconosciuta) && empty($dataRicezione)) {
            write($row, 36, '');
        } else {
            $idCentri = array();
            if ($CRP)
                $idCentri[] = $CRP['station']->Id;
            else {
                if ($ai->getDefaultCRP()) {
                    $idCentri[] = $ai->getDefaultCRP()->Id;
                }
            }

            if ($CRA)
                $idCentri[] = $CRA['station']->Id;
            else {
                if ($ai->getDefaultCRA()) {
                    $idCentri[] = $ai->getDefaultCRA()->Id;
                }
            }

            if ($CP)
                $idCentri[] = $CP['station']->Id;
            else {
                if ($ai->getDefaultCP()) {
                    $idCentri[] = $ai->getDefaultCP()->Id;
                }
            }

            if ($CD)
                $idCentri[] = $CD['station']->Id;
            else {
                if ($ai->getDefaultCD()) {
                    $idCentri[] = $ai->getDefaultCD()->Id;
                }
            }
//            echo 'MailId:' . $mail->getMailid() . ' => On-TIME: ' . $ai->getOnTime() . PHP_EOL;
            $ontimeE2E = 0;
            if ($ai->getOnTime() === 0) {
                write($row, 36, 0);
            } else {
                if (!empty($CD) && !empty($CD['out'])) {
                    $recDate = $mail->getReceivingDate('Ymd');
                    if (!empty($recDate)) {
                        $uscitaCD = $CD['out']->format('Ymd');
                        if ($uscitaCD == $recDate) {
                            write($row, 36, 1);
                        } else {
                            $pbt = null;
                            if ($mail->getPostboxAddress() != null) {
                                $pbt = PostboxTimeQuery::create()->where('cap="' . $mail->getSendingCap() . '" AND address="' . addslashes($mail->getPostboxAddress()) . '"')->findOne();
                            } else {
                                $pbt = PostboxTimeQuery::create()->where("cap='" . $mail->getSendingCap() . "'")->findOne();
                            }
                            if ($pbt != null) {
                                $ontimeE2E = getOnTimeE2E($mail, $idCentri, new \DateTime($mail->getSendingDate('Y-m-d') . ' ' . $pbt->getTime('H:i:s'))) ? 1 : 0;
                            } else {
                                $ontimeE2E = getOnTimeE2E($mail, $idCentri, new \DateTime($mail->getSendingDate('Y-m-d') . ' ' . $mail->getPostboxTime('H:i:s'))) ? 1 : 0;
                            }
                            write($row, 36, $ontimeE2E);
                        }
                    }
                } else {//($ai->getOnTime() === 1 || $ai->getOnTime() === 2) &&
                    if ($mail->getSendingDate('m') >= 7 && $mail->getSendingDate('Y') >= 2015) { //[&& $mail->getSendingDate('m') >= 7] introdotto il giorno 21/07/2015 per problematica su ambiguità gestione spedizione
                        $pbt = null;
                        if ($mail->getPostboxAddress() != null) {
                            $pbt = PostboxTimeQuery::create()->where('cap="' . $mail->getSendingCap() . '" AND address="' . addslashes($mail->getPostboxAddress()) . '"')->findOne();
                        } else {
                            $pbt = PostboxTimeQuery::create()->where("cap='" . $mail->getSendingCap() . "'")->findOne();
                        }
                        if ($pbt != null) {
                            $ontimeE2E = getOnTimeE2E($mail, $idCentri, new \DateTime($mail->getSendingDate('Y-m-d') . ' ' . $pbt->getTime('H:i:s'))) ? 1 : 0;
                        } else {
                            $ontimeE2E = getOnTimeE2E($mail, $idCentri, new \DateTime($mail->getSendingDate('Y-m-d') . ' ' . $mail->getPostboxTime('H:i:s'))) ? 1 : 0;
                        }
                        write($row, 36, $ontimeE2E);
                    }
                }
//                echo 'MailId:' . $mail->getMailid() . ' => ON-TIME E2E: ' . $ontimeE2E . PHP_EOL;
            }
//            $cdOut = '';
//
//            if ($CD) {
//                if (!empty($CD['out']) && $CD['out'] instanceof DateTime) {
//                    $cdOut = @date('Ymd', strtotime($CD['out']->format('Y-m-d H:i:s')));
//                    $rDate = $mail->getReceivingDate('Ymd');
//                    if ($cdOut != $rDate) {
//                        write($row, 36, 0);
//                    }
//                }
//            } else {
//                $pbt = null;
//                if ($mail->getPostboxAddress() != null) {
//                    $pbt = PostboxTimeQuery::create()->where('cap="' . $mail->getSendingCap() . '" AND address="' . addslashes($mail->getPostboxAddress()) . '"')->findOne();
//                } else {
//                    $pbt = PostboxTimeQuery::create()->where("cap='" . $mail->getSendingCap() . "'")->findOne();
//                }
//                if ($pbt != null) {
//                    write($row, 36, getOnTimeE2E($mail, $idCentri, new \DateTime($mail->getSendingDate('Y-m-d') . ' ' . $pbt->getTime('H:i:s'))) ? 1 : 0);
//                } else {
//                    write($row, 36, getOnTimeE2E($mail, $idCentri, new \DateTime($mail->getSendingDate('Y-m-d') . ' ' . $mail->getPostboxTime('H:i:s'))) ? 1 : 0);
//                }
//            }
        }
        // var_dump(getOnTimeE2E($mail, $idCentri));
    }

    echo ".";
    $errorMsg[] = $ai->errorsMsg;
    $warningMsg[] = $ai->warningMsg;
    $row++;
    $ai->__destruct();
    unset($ai);
    if ($CRP) unset($CRP);
    if ($CRA) unset($CRA);
    if ($CP) unset($CP);
    if ($CD) unset($CD);
    gc_collect_cycles();
}
echo "\n";

function write($row, $col, $value)
{
    if ($value === "") return;
    global $sheet, $formats;
    $sheet->write($row, $col, $value, $formats[$col]);
}

function parseStationDate($dateTime)
{
    global $eb;
    if ($dateTime === FALSE) return "";
    // format("d/m/Y H:i")
    return $eb->packDate($dateTime->getTimestamp());
}

function getOnTimeE2E($mail, $idCentri, $pbt)
{
    $sendDate = new DateTime($mail->getSendingDate('Y-m-d'));
    $receiveDate = new DateTime($mail->getReceivingDate('Y-m-d'));
    $desiredReceiveDate = null;

    $sendTimeStamp = $sendDate->format('Y-m-d') . ' ' . $mail->getSendingHour('H:i:s');
    $pbTimeStamp = $sendDate->format('Y-m-d') . ' ' . $pbt->format('H:i:s');

    // Se il test � stato imbucato oltre l'orario limite, setto come data di invio il giorno successivo
    if (strtotime($sendTimeStamp) >= strtotime($pbTimeStamp)) {
        if ($mail->getSendingDate('N') == 5)
            $sendDate->modify('+3 days');
        elseif ($mail->getSendingDate('N') == 6) {
            $sendDate->modify('+2 days');
        } else {
            $sendDate->modify('+1 day');
        }
    }

    // Se la data di spedizione risulta essere sabato o domenica, considero come data utile il lunedì successivo
    if ($sendDate->format('N') == 6) {
        $sendDate->modify('+2 days');
    } elseif ($sendDate->format('N') == 7) {
        $sendDate->modify('+1 day');
    }

    if (isHoliday($sendDate, $idCentri)) {
        $sendDate = getFirstDayAfterHoliday($sendDate, $idCentri);
    }

    //una volta calcolata la data reale di spedizione, calcolo la data desiderata di ricezione
    $desiredReceiveDate = new DateTime($sendDate->format('Y-m-d'));
    if ($sendDate->format('N') == 5)
        $desiredReceiveDate->modify('+3 days');
    elseif ($sendDate->format('N') == 6)
        $desiredReceiveDate->modify('+2 days');
    else
        $desiredReceiveDate->modify('+1 day');

    global $warningMsg;
    $warningMsg[][0] = $mail->getMailid() . '=' . $sendDate->format('Y-m-d') . ' - ' . $receiveDate->format('Y-m-d') . ' desired receiving date: ' . $desiredReceiveDate->format('Y-m-d') . ' \n\n';

    //se la data reale di ricezione combacia con la data di desiderata ricezione, termino
    if (strtotime($receiveDate->format('Y-m-d')) <= strtotime($desiredReceiveDate->format('Y-m-d')))
        return true;

    //se la data reale di ricezione è diversa dalla data di desiderata ricezione, controllo se la data di desiderata ricezione è un festivo
    if (isHoliday($desiredReceiveDate, $idCentri)) {
        $warningMsg[][0] = 'Festivo in uno dei centri coinvolti. Giorno da considerare per la ricezione: ' . getFirstDayAfterHoliday($desiredReceiveDate, $idCentri)->format('d-m-Y');
        $desiredReceiveDate = getFirstDayAfterHoliday($desiredReceiveDate, $idCentri);
    }

    //se la data reale di ricezione combacia con la data di desiderata ricezione, termino
    if (strtotime($receiveDate->format('Y-m-d')) <= strtotime($desiredReceiveDate->format('Y-m-d')))
        return true;

    // Se ho superato tutti i controlli, la spedizione risulta essere off-time
    return false;
}

function isHoliday(DateTime $sendDate, $idCentri)
{
    $holidays = \HolidaysQuery::create()->where('date = \'' . $sendDate->format('Y-m-d') . '\' AND (station_masterdata_id IS NULL OR station_masterdata_id IN(' . implode(',', $idCentri) . '))')
        ->orderBy("date", \Criteria::ASC)
        ->find();
    $res = (!empty($holidays)) && (count($holidays) > 0);

    return $res;
}

function getFirstDayAfterHoliday(DateTime $sendDate, $idCentri)
{
    while (isHoliday($sendDate, $idCentri) !== FALSE) {
        $sendDate->modify('+1 day');
    }
    return $sendDate;
}

/**
 * Una spedizione viene chiusa (e quindi non più elaborata) dopo 30 giorni
 * dall'ultima lettura dei Transpoder oppure quando viene inserita una nuova
 * spedizione con lo stesso Transponder. Per chiudere la spedizione è necessario
 * popolare l'apposito campo del database con la data di fine analisi.
 * L'elaborazione dell'ontime dovrà tener conto di tale data come ultima lettura
 * da recuperare.
 * In presenza di tale data inoltre, il job corrente, deve riportare l'oggetto
 * JSON statico all'interno dell'apposita colonna del database. Tale JSON verrà
 * utilizzato per le future generazioni del report e per l'interfaccia
 * grafica.
 */


function sendErrorToAdministrators($errors, $warnings)
{
    global $output, $title;
    $userType = \UserTypeQuery::create()->filterByName("admin")->findOne();
    $users = \UserQuery::create()->filterByUserType($userType)->where('email IS NOT NULL')->find();

    $headers = "From: no-reply@psquality.it\r\n"
        . "Reply-To: no-reply@psquality.it\r\n"
        . "X-Mailer: PHP/" . phpversion();

    /* @var $user \User */
    foreach ($users as $user) {
        \Propel::log("Prepare email for " . $user->getEmail(), \Propel::LOG_INFO);

        $welcome = "Buongiorno " . $user->getName() . ",\n\n";
        $welcome .= "è stato generato un nuovo report $output.\n";
        $welcome .= "\nDi seguito troverai alcune note che ti aiutaranno a comprendere eventuali errori effettuati dai panelisti in modo da apportare le dovute correzioni.\n\n";
        $welcome .= $errors;
        $welcome .= "\n\nDi seguito alcuni avvertimenti:\n\n";
        $welcome .= $warnings;

        mail($user->getEmail(), $title, $welcome . "\n\n---\nPSQ Tracker", $headers);
    }
}

// Prima di salvare mi assicuro che esistano le cartelle:
if (!file_exists(dirname($output))) {
    mkdir(dirname($output), 0777, true);
}


$eb->save($output);

if (count($errorMsg) > 0 || count($warningMsg) > 0) {
    $errors = "";
    for ($i = 0; $i < count($errorMsg); $i++) {
        for ($j = 0; $j < count($errorMsg[$i]); $j++) {
            $errors .= $errorMsg[$i][$j] . "\n\n";
        }

    }
    echo $errors;

    $warnings = "";
    for ($i = 0; $i < count($warningMsg); $i++) {
        for ($j = 0; $j < count($warningMsg[$i]); $j++) {
            $warnings .= $warningMsg[$i][$j] . "\n\n";
        }

    }
    echo $warnings;

    if (!$alt && $period == "YTD" && ($type == "naz" || $type == "int")) sendErrorToAdministrators($errors, $warnings);
}

echo "File $output saved successfully\n";

}
?> 