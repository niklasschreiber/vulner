var isIE = document.all?true:false;
var isNS = document.layers?true:false;
var gSoglia; ///gSoglia= 0 si può inserire lo 0 

function Ricerca_OP()
{
	// entrambi i campi sono obbligatori
	if ( (document.cerca.R_GT.value == "") || (document.cerca.R_CC.value == "") )
	{
		alert("Both fields are required");
		//document.cerca.R_CC.focus();
		return false;
	}
}

function checkOperator(tipo)
{
	 var fail = false;
	
	if (document.inputform.countrySelect.selectedIndex == 0)
	{
		alert('Please choose a country.');
		return false;
	}
	$("input").each(function() 
	{
	   if( this.type == 'text' && this.value == ""  && ( this.name != "GT"  && this.name != "")
	       && ( this.name != "GT"  && this.name != "TADIG") )
		{
			alert('Please complete all required fields before continuing.');
		    $(this).focus();
			fail = true;
			return false;
		}
	});

	if(fail) 
	{
   	 	return false;
    }
	 
	//document.inputform.NAME_OP.value =  document.inputform.NAME_OP.value.toUpperCase();
	document.inputform.COD_OP.value  =  document.inputform.COD_OP.value.toUpperCase();
	document.inputform.TADIG.value  =  document.inputform.TADIG.value.toUpperCase();
	
	return true;
}
function showtip(obj, text)
{
	obj.title = text;
}


//  TRIM ---------------------------------------------------------------------		
function trim(inputString)															
{																					
	// Removes leading and trailing spaces from the passed string. Also removes		
	// consecutive spaces and replaces it with one space. If something besides		
	// a string is passed in (null, custom object, etc.) then return the input.		
	if (typeof inputString != 'string') { return inputString; }						
	var retValue = inputString;														
	var ch = retValue.substring(0, 1);												
	while (ch == ' ') { // Check for spaces at the beginning of the string			
		retValue = retValue.substring(1, retValue.length);							
		ch = retValue.substring(0, 1);												
	}																				
	ch = retValue.substring(retValue.length-1, retValue.length);					
	while (ch == ' ') { // Check for spaces at the end of the string				
		retValue = retValue.substring(0, retValue.length-1);						
		ch = retValue.substring(retValue.length-1, retValue.length);				
	}																				
	while (retValue.indexOf('  ') != -1) { // Note that there are two spaces in the string - look for multiple spaces within the string		
		retValue = retValue.substring(0, retValue.indexOf('  ')) + retValue.substring(retValue.indexOf('  ')+1, retValue.length); // Again, there are two spaces in each of the strings		
	}																				
	return retValue; // Return the trimmed string back to the user					
}																					

//**********************************************************************************************************************
function setArrayPaesi() 
{
	var i;
	document.inputform.countrySelect.length = Paesi.length;
	for (i=0; i<Paesi.length; i++)
	{
		document.inputform.countrySelect.options[i].text = Paesi[i][0];
	document.inputform.countrySelect.options[i].value = Paesi[i][0];
	}
}

function get_CC() 
{ 
	document.inputform.CC.value = Paesi[document.inputform.countrySelect.options.selectedIndex][1];
	document.inputform.CC2.value = Paesi[document.inputform.countrySelect.options.selectedIndex][1];
	document.inputform.MAX_TS.value = Paesi[document.inputform.countrySelect.options.selectedIndex][2];
	document.inputform.R_TS_I.value = Paesi[document.inputform.countrySelect.options.selectedIndex][3];
} 

// *********************************************************************************************************
//                           OPERATOR GT
// *********************************************************************************************************
 function setArrayGT() 
 {
  document.inputform.GTSelected.length = listaGT.length;
  for (i=0; i<listaGT.length; i++)
    document.inputform.GTSelected.options[i] = listaGT[i];
}

function addGT() 
{
	//controllo che non il GT non sia già inserito
	j=0;
	while ( j>=0 && j<document.inputform.GTSelected.length ) 
	{
		var appo = document.inputform.GTSelected.options[j].value;
		var appo2 = document.inputform.CC2.value + document.inputform.GT.value;
		if( trim(appo) == trim(appo2) )
				j=-1;
			else ++j;
	}
	if (j>=0) 
	{
		listaGT.length = listaGT.length +1;
		document.inputform.GTSelected.options[listaGT.length -1] = new Option(document.inputform.CC2.value + document.inputform.GT.value, document.inputform.CC2.value + document.inputform.GT.value);
	}
}

function delGT()
{
	with (document.inputform.GTSelected) 
	{
	  for(i=0; i<length; i++) 
	  {
		if (options[i].selected == true) 
		{
			//scrivo nel campo DEL solo i GT che erano già presenti nel db
			if( options[i].value.substr(0,1) == "*")
				document.inputform.DELGT.value  += options[i].value + ":";
		  j=i;
		  while ( j<length-1 ) 
		  {
				options[j] = new Option(options[j+1].text,options[j+1].value);
				options[j].selected = options[j+1].selected;
				++j;
		  }
		  options[length-1] = null;
		  --i;
		listaGT.length = listaGT.length -1;
		}  
	}  selectedIndex = -1; }
}


function prepara_valori_GT()
{
	for (i=0; i< document.inputform.GTSelected.length; i++)
	{
		if (i == 0)
			document.inputform.VALORI.value= document.inputform.GTSelected.options[i].value;
		else
			document.inputform.VALORI.value += ":" + document.inputform.GTSelected.options[i].value;
	}
	if(document.inputform.GTSelected.length > 0)
		document.inputform.VALORI.value += ":";
}

// *********************************************************************************************************
//                           OPERATOR BORDER GT
// *********************************************************************************************************
function setArrayGT_Border() 
 {
  document.inputform.GTBorder.length = listaGT_Border.length;
  for (i=0; i<listaGT_Border.length; i++)
    document.inputform.GTBorder.options[i] = listaGT_Border[i];
}

function addGT_Border() 
{
	//controllo che il GT non sia già inserito
	j=0;
	while ( j>=0 && j<document.inputform.GTBorder.length ) 
	{
		var appo = document.inputform.GTBorder.options[j].value;
		var appo2 = document.inputform.CC2.value + document.inputform.GT.value;
		if( trim(appo) == trim(appo2) )
				j=-1;
			else ++j;
	}
	if (j>=0) 
	{
		listaGT_Border.length = listaGT_Border.length +1;
		document.inputform.GTBorder.options[listaGT_Border.length -1] = new Option(document.inputform.CC2.value + document.inputform.GT.value, document.inputform.CC2.value + document.inputform.GT.value);
	}
}

function delGT_Border()
{
	with (document.inputform.GTBorder) 
	{
	  for(i=0; i<length; i++) 
	  {
		if (options[i].selected == true) 
		{
			//scrivo nel campo DEL solo i GT che erano già presenti nel db
			if( options[i].value.substr(0,1) == "*")
				document.inputform.DELGT_B.value  += options[i].value + ":";
		  j=i;
		  while ( j<length-1 ) 
		  {
				options[j] = new Option(options[j+1].text,options[j+1].value);
				options[j].selected = options[j+1].selected;
				++j;
		  }
		  options[length-1] = null;
		  --i;
		listaGT_Border.length = listaGT_Border.length -1;
		}  
	}  selectedIndex = -1; }
}

function prepara_valori_GT_Border()
{
	for (i=0; i< document.inputform.GTBorder.length; i++)
	{
		if (i == 0)
			document.inputform.VALORI_B.value= document.inputform.GTBorder.options[i].value;
		else
			document.inputform.VALORI_B.value += ":" + document.inputform.GTBorder.options[i].value;
	}
	if(document.inputform.GTBorder.length > 0)
		document.inputform.VALORI_B.value += ":";
}


//************************************************************************************************************

function addMGT() 
{
	//controllo che MGT non sia già inserito
	j=0;
	while ( j>=0 && j<document.inputform.GTSelected.length ) 
	{
		var appo = document.inputform.GTSelected.options[j].value;
		var appo2 = document.inputform.GT.value;
		if( trim(appo) == trim(appo2) )
				j=-1;
			else ++j;
	}
	if (j>=0) 
	{
		listaGT.length = listaGT.length +1;
		document.inputform.GTSelected.options[listaGT.length -1] = new Option(document.inputform.MGT.value,  document.inputform.MGT.value);
	}
}



function prepara_valori()
{
	for (i=0; i< document.inputform.operatorSelected.length; i++)
	{
		if (i == 0)
			document.inputform.VALORI.value= document.inputform.operatorSelected.options[i].value;
		else
			document.inputform.VALORI.value += ":" + document.inputform.operatorSelected.options[i].value;
	}
	if(document.inputform.operatorSelected.length > 0)
		document.inputform.VALORI.value += ":";
	
	document.inputform.GRUPPO.value =  document.inputform.GRUPPO.value.toUpperCase();

}

 function setMCC() {
  document.inputform.countrySelect.length = mccOptions.length;
  for (i=0; i<mccOptions.length; i++)
    document.inputform.countrySelect.options[i] = mccOptions[i];
    $('.chosen-select').trigger("chosen:updated");
    $('.noSearch').trigger("chosen:updated");
}

function setMNC(ctry) {
 with (document.inputform) {
  for(var i=(operatorSelect.length-1); i>=0; i--)
    operatorSelect.options[i]=null;
  StringToSearch=new String(fOperator.value);
  var k = -1;
  
  for (i=0; i<mncOptions[ctry].length; i++) {
    var s = new String(mncOptions[ctry][i].text);
    if (StringToSearch != "") {
      if ( s.toUpperCase().indexOf(StringToSearch.toUpperCase()) != -1 )
        operatorSelect.options[++k] = mncOptions[ctry][i];
    } else operatorSelect.options[++k] = mncOptions[ctry][i];
  }
    $('.chosen-select').trigger("chosen:updated");
    $('.noSearch').trigger("chosen:updated");
  
  operatorSelect.selectedIndex = 0;
 // if (document.inputform.VLRSelect != undefined)
 // {
	//VLRSelect.selectedIndex = 0;
	//VLRPostfix.value = "";
  //}
  
 }
}


//-------------------------------------------------------------------------------------------------------------
																			
//  Conta caratteri disponibili per il messaggio  ----------------------------			
function ContaCar(campo, car, Max)																		
{	
	var Lung;																			
	Lung = eval("document.inputform."+campo+".value.length");
	valore = eval("document.inputform."+campo);
	conta  = eval("document.inputform."+car);
	// se è oltre la lunghezza massima															
	if (Lung > Max)																			
	{																							
		// elimina tutti gli spazi inutili														
		valore.value = trim(valore.value);				
		Lung = valore.value.length;								
		// se è ancora troppo lunga																
		if (Lung > Max)																		
		{																						
			dummy = new String(valore.value);								
			// prende solo i primi n.. caratteri												
			valore.value = dummy.substr(0,Max);							
			Lung=Max;																		
		}																						
	}							
	conta.value = Max - Lung;											
}

//-----------------------------------------------------------------------------
function Inserisci_testo_variabile()
{
	for (i=0; i<document.inputform.TESTO_VARIABILE.length; i++)
	{
		if (document.inputform.TESTO_VARIABILE.options[i].selected == true)
		{
			document.inputform.NASCOSTO.value = document.inputform.TESTO_VARIABILE.options[i].innerText;
		}
	}
}

//nasconde la gif 
//0 = Nasconde
//1 = appare
function togliegif(spanID, tipo) 
{
	thisMenu = document.getElementById(spanID).style;
	if (tipo == 0)
		thisMenu.display = "none";
	else
		thisMenu.display = "inline";
}

function CheckCerca()
{
	if(( trim(document.cerca.IMSI.value.length == 0) ) || (document.cerca.IMSI.value.length < 15))
	{
		alert("IMSI must be 15 characters long");
		document.cerca.IMSI.focus();
		return false;
	}
	else
		return true;				
}
//**************************************************************************************
function CheckStrategy()
{
	if (document.inputform.TMAX.value == "" )
	{
		alert("Seconds limits (TMax) is mandatory");
		document.inputform.TMAX.focus()
		return false;
	}
	if(document.inputform.TMAX.value.substring(0,1) == '0')
	{
		alert("The first character of Seconds limits (TMax) cannot be 0 ");
		document.inputform.TMAX.focus();
		return false;
	}
	if (document.inputform.TMIN.value == "" )
	{
		alert("Seconds between LU (TMin) is mandatory");
		document.inputform.TMIN.focus()
		return false;
	}
	if(document.inputform.TMIN.value.substring(0,1) == '0')
	{
		alert("The first character of Seconds between LU (TMin) cannot be 0 ");
		document.inputform.TMIN.focus();
		return false;
	}
}
function CheckSoglie(tipo)
{
	var flag = 0;
	if (tipo == "Insert")
	{
		if((document.inputform.countrySelect.options.selectedIndex == 0 ) &&
			(document.inputform.GroupPASelect.options.selectedIndex == 0) )	
		{
			alert("Country or Group Countries is mandatory");
			return false;
		}
		if((document.inputform.countrySelect.options.selectedIndex > 0 ) &&
			(document.inputform.operatorSelect.options.selectedIndex < 0) )	
		{		
			alert("Operator is mandatory");
			document.inputform.operatorSelect.focus();
			return false;
		}
		
		if((document.inputform.GroupPASelect.options.selectedIndex != 0 ) &&
			(document.inputform.GroupOPSelect.options.selectedIndex == 0) )	
		{
			alert("Group Operators  is mandatory");
			document.inputform.GroupOPSelect.focus();
			return false;
		}

		if (document.inputform.FASCIA_DA.value == "" )
		{
			alert("Time from is mandatory");
			document.inputform.FASCIA_DA.focus();
			return false;
		}
		if (document.inputform.FASCIA_A.value == "" )
		{
			alert("Time to is mandatory");
			document.inputform.FASCIA_A.focus();
			return false;
		}
		//  Time																	
		dummy = new String(trim(document.inputform.FASCIA_DA.value));					
		dummy2 = new String(trim(document.inputform.FASCIA_A.value));					
		if (dummy > dummy2)															
		{	
			alert("'Time to' must be more greater than 'Time from'");		
			return false;															
		}																			

		if ( (dummy.length < 5 )||(dummy.substr(2,1) != ':') ||
			 (dummy2.length < 5 )||(dummy2.substr(2,1) != ':'))			
		{																			
			alert('Time  - Format not valid (HH:MM)');		
			return false;															
		}																			
		if ( (dummy.substr(0,2) > 23) || (dummy2.substr(0,2) > 23) )												
		{																			
			alert('Time	 - Valid hours: 00-23');								
			return false;															
		}																			
		if ( (dummy.substr(3,2) > 59 ||dummy2.substr(3,2) > 59))													
		{																			
			alert('Time	 - Valid minutes: 00-59');								
			return false;															
		}																			

		if (document.inputform.LUN.checked != "" )
			flag = 1;
		if (document.inputform.MAR.checked != "" )
			flag = 1;
		if (document.inputform.MER.checked != "" )
			flag = 1;
		if (document.inputform.GIO.checked != "" )
			flag = 1;
		if (document.inputform.VEN.checked != "" )
			flag = 1;
		if (document.inputform.SAB.checked != "" )
			flag = 1;
		if (document.inputform.DOM.checked != "" )
			flag = 1;
		
		if(flag == 0)
		{																			
			alert('Days-week is mandatory');		
			return false;															
		}	
		
		if(document.inputform.countrySelect.options.selectedIndex != 0 ) 
		{
			document.inputform.GR_PA.value = document.inputform.countrySelect.value;
			document.inputform.GR_OP.value = document.inputform.operatorSelect.value;
		}
		else if (document.inputform.GroupPASelect.options.selectedIndex != 0 ) 
		{
			document.inputform.GR_PA.value = document.inputform.GroupPASelect.value;
			document.inputform.GR_OP.value = document.inputform.GroupOPSelect.value;
		}	
		
		if(document.inputform.GroupOPSelect.options.selectedIndex != 0 ) 
		{
			if (document.inputform.SOGLIA.value == 0)
			{
				alert("Threshold must be greater than 0");
				document.inputform.SOGLIA.focus();
				return false;
			}
		}
		
	}
	else
	{
		//se gSoglia = 1 è STATO INSERITO UN GRUPPO
		if (gSoglia == 1) 
		{
			if (document.inputform.SOGLIA.value == 0)
			{
				alert("Threshold must be greater than 0");
				document.inputform.SOGLIA.focus();
				return false;
			}
		}
	}
	
	if (document.inputform.SOGLIA.value > 100)
	{
		alert("The Threshold can not be greater than 100");
		document.inputform.SOGLIA.focus()
		return false;
	}
	
	if (document.inputform.PESO.value > 127)
	{
		alert("Weight must be Within 0 and 127");
		document.inputform.PESO.focus()
		return false;
	}
}

function CheckPre_Steering(tipo)
{
	var flag = 0;
	if (tipo == "Insert")
	{
		if(document.inputform.countrySelect.options.selectedIndex == 0 ) 
		{
			alert("Country is mandatory");
			document.inputform.countrySelect.focus();
			return false;
		}
		if(document.inputform.operatorSelect.options.selectedIndex <= 0) 	
		{		
			alert("Operator is mandatory");
			document.inputform.operatorSelect.focus();
			return false;
		}
		if (document.inputform.FASCIA_DA.value == "" )
		{
			alert("Time from is mandatory");
			document.inputform.FASCIA_DA.focus();
			return false;
		}
		if (document.inputform.FASCIA_A.value == "" )
		{
			alert("Time to is mandatory");
			document.inputform.FASCIA_A.focus();
			return false;
		}
		//  Time																	
		dummy = new String(trim(document.inputform.FASCIA_DA.value));					
		dummy2 = new String(trim(document.inputform.FASCIA_A.value));					
		if (dummy > dummy2)															
		{	
			alert("'Time to' must be more greater than 'Time from'");		
			return false;															
		}																			

		if ( (dummy.length < 5 )||(dummy.substr(2,1) != ':') ||
			 (dummy2.length < 5 )||(dummy2.substr(2,1) != ':'))			
		{																			
			alert('Time  - Format not valid (HH:MM)');		
			return false;															
		}																			
		if ( (dummy.substr(0,2) > 23) || (dummy2.substr(0,2) > 23) )												
		{																			
			alert('Time	 - Valid hours: 00-23');								
			return false;															
		}																			
		if ( (dummy.substr(3,2) > 59 ||dummy2.substr(3,2) > 59))													
		{																			
			alert('Time	 - Valid minutes: 00-59');								
			return false;															
		}																			

		if (document.inputform.LUN.checked != "" )
			flag = 1;
		if (document.inputform.MAR.checked != "" )
			flag = 1;
		if (document.inputform.MER.checked != "" )
			flag = 1;
		if (document.inputform.GIO.checked != "" )
			flag = 1;
		if (document.inputform.VEN.checked != "" )
			flag = 1;
		if (document.inputform.SAB.checked != "" )
			flag = 1;
		if (document.inputform.DOM.checked != "" )
			flag = 1;
		
		if(flag == 0)
		{																			
			alert('Days-week is mandatory');		
			return false;															
		}	
	}		
}
function abilitaimei(valore)
{
	// disabilito tutti i campi
	for(i=2; i <=10; i++)															
	{
		var tmp= 'document.inputform.IMEI_INFO' + i ;
		//dummy = new String(eval(tmp));
		eval(tmp).style.background	=	'lightgrey';
		eval(tmp).disabled			=	true;
	}
	// valore * 1 restituisce un numero( forza conversione della variabile in num)
	var pp = valore*1 +1;
	// abilito i campi che indica Tmax attempt Allowed 
	for(i=2; i <=pp; i++)															
	{
		var tmp= 'document.inputform.IMEI_INFO' + i ;
		//dummy = new String(eval(tmp));
		eval(tmp).style.background	=	'white';
		eval(tmp).disabled			=	false;
	}
}
function CheckImsi(tipo)
{
	//tipo 1= inserimento - tipo=3 Black list
	if ((tipo == '1') || (tipo == '3'))
	{
		if(( trim(document.inputform.IMSI.value.length == 0) ) || (document.inputform.IMSI.value.length < 15))
		{
			alert("IMSI is mandatory and must be 15 characters long");
			document.inputform.IMSI.focus()
			return false;
		}
	}
	if(tipo != '3') //ins e upd IMSI
	{
		if (document.inputform.countrySelect.value    == "" )
		{
			alert("Country is mandatory");
			document.inputform.PAESE.focus();
			return false;
		}
		if (document.inputform.NUM_TS.value  == "" )
		{
			alert("#TS is mandatory");
			document.inputform.NUM_TS.focus()
			return false;
		}
		
		if (document.inputform.ERROR_LU.value  > 32767 )
		{
			alert("Max Value: 32767");
			document.inputform.ERROR_LU.focus()
			return false;
		}


		// Timestamp																				
		dummy = new String(trim(document.inputform.TIMESTAMP.value.substring(6,10)+
						document.inputform.TIMESTAMP.value.substring(3,5)+
						document.inputform.TIMESTAMP.value.substring(0,2)));	

		if (dummy.length > 0)															
		{																				
			if (dummy.length < 8 || isNaN(dummy))										
			{																			
				alert('Timestamp - Format not valid (DD/MM/YYYY)');						
				return false;															
			}																			
			if (dummy.substr(4,2) > 12 || dummy.substr(4,2) < 1)						
			{																			
				alert('Timestamp - Valid months: 01-12');								
				return false;															
			}																			
			if ((dummy.substr(4,2) == 11 || dummy.substr(4,2) == 4 || dummy.substr(4,2) == 6 || dummy.substr(4,2) == 9) && dummy.substr(6,2) > 30)	
			{																			
				alert('Timestamp - Months 04, 06, 09, 11 have 30 days');				
				return false;															
			}																			
			if ((dummy.substr(4,2) == 1 || dummy.substr(4,2) == 3 || dummy.substr(4,2) == 5 || dummy.substr(4,2) == 7 || dummy.substr(4,2) == 8 || dummy.substr(4,2) == 10 || dummy.substr(4,2) == 12) && dummy.substr(6,2) > 31)	
			{																			
				alert('Timestamp - Months 01, 03, 05, 07, 08, 10, 12 have 31 days');	
				return false;															
			}																			
			if (dummy.substr(4,2) == 2 && dummy.substr(6,2) > 28)						
			{																			
				if ((dummy.substr(0,4) % 4) == 0)										
				{																		
					if (dummy.substr(6,2) > 29)											
					{																	
						alert('Timestamp - February have 29 days');					
						return false;													
					}																	
				}																		
				else																	
				{																		
					alert('Timestamp - February have 28 days');						
					return false;														
				}																		
			}																			
		}																				
		else 					
		{																				
			alert('Timestamp is mandatory');			
			return false;																
		}		

		//  Time																	
		dummy = new String(trim(document.inputform.ORA.value));					
		if (dummy.length > 0)															
		{																				
			if ( (dummy.length < 8 )||(dummy.substr(2,1) != ':') || (dummy.substr(5,1) != ':') )			
			{																			
				alert('ORA Consenso	 - Format not valid (HH:MM:SS)');		
				document.inputform.ORA.focus();
				return false;															
			}																			
			if (dummy.substr(0,2) > 23)													
			{																			
				alert('ORA Consenso	 - Valid hours: 00-23');								
				document.inputform.ORA.focus();
				return false;															
			}																			
			if (dummy.substr(3,2) > 59)													
			{																			
				alert('ORA Consenso	 - Valid minutes: 00-59');								
				document.inputform.ORA.focus();
				return false;															
			}																			
			if (dummy.substr(6,2) > 59)													
			{																			
				alert('ORA Consenso	 - Valid seconds: 00-59');								
				document.inputform.ORA.focus();
				return false;															
			}									
		}																				
	}
}
function check_net_nodes(tipo)
{
	//tipo 1= inserimento 
	if (tipo == '1') 
	{
		if (document.inputform.PC.value  > 32767 )
		{
			alert("Max Value: 32767");
			document.inputform.PC.focus()
			return false;
		}
	}
}

function scriviNum_TS()
{
//copia il valore che c'è dopo il ";"
var num = document.inputform.PAESE.value.indexOf(';');
document.inputform.NUM_TS.value = document.inputform.PAESE.value.substr(num+1);
}

function newWindow(file,window)
{
	 msgWindow=open(file,window,'toolbar=yes,location=yes,directories=no,status=no,menubar=yes,scrollbars=yes,resizable=yes,copyhistory=yes,width=1000,height=500');
	 if (msgWindow.opener == null) 
		 msgWindow.opener = self;
}

function abilitaUpd()
{
	var cBox1 = document.inputform.NEW.checked;
	var cBox2 = document.inputform.DEL.checked;
	
	if((cBox1 == true) || (cBox2 == true) )
		document.inputform.UPD.disabled = false;
	else if ((cBox1 == false) && (cBox2 == false) )
		document.inputform.UPD.disabled = true;
}
function Pulisci_RicercaMaxTS(tipo)
{
	switch (tipo)
	{
	case 1:
		document.cerca.COUNTRY.value = '';
		break;
	case 2:
		document.cerca.PAESE.value = '';
		break;
	}
}

function checkMaxTS(tipo)
{
	if (tipo == 'Insert')
	{
		if (document.inputform.PAESE.value == "" )
		{
			alert("Country Code is mandatory");
			document.inputform.PAESE.focus();
			return false;
		}
		if (document.inputform.DEN_PAESE.value == "" )
		{
			alert("Country is mandatory");
			document.inputform.DEN_PAESE.focus();
			return false;
		}
	// commentato vers. A09	
	//document.inputform.DEN_PAESE.value = document.inputform.DEN_PAESE.value.toUpperCase();
	}
}


function conferma_BL()
{
	var msgconf = '';
	var tipo = '';

	if (document.inputform.FILE_INPUT.value == "")
	{
		alert("Insert Input File");
		document.inputform.FILE_INPUT.focus();
		return false;
	}

	if (document.inputform.TIPO[0].checked )
	{
		tipo = "INSERTED into ";
	}
	else
		tipo = "DELETED from ";

	msgconf = 'The record contained in the input file will be '+ tipo +'IMSI DB\n ';
	msgconf +=  'do you want to continue?';
	var ret = confirm(msgconf);
	if (ret == true)
		return true;				
	else
		return false;
}

function conferma_Imp()
{
	if (document.inputform.FILE_INPUT.value == "")
	{
		alert("Insert Input File");
		document.inputform.FILE_INPUT.focus();
		return false;
	}
}

function attivaPostfix()
{
	var post= 'document.inputform.VLRPostfix' ;
	var vlrpre= 'document.inputform.VLRSelect' ;	
	
	if(document.inputform.operatorSelect.options.selectedIndex > 0) 	
	{
		eval(vlrpre).disabled	=	false;
		$('.chosen-select').trigger("chosen:updated");
	}
	else
	{
		eval(vlrpre).disabled	=	true;
		eval(vlrpre).options.selectedIndex = 0;
		$('.chosen-select').trigger("chosen:updated");
	}
	
	if(document.inputform.VLRSelect.selectedIndex < 1)
	{
		eval(post).style.background	=	'lightgrey';
		eval(post).disabled			=	true;
		eval(post).value			= "";
	}
	else
	{
		eval(post).style.background	=	'white';
		eval(post).disabled			=	false;
		eval(post).maxLength		=	(24 - document.inputform.VLRSelect.value.length);
	}
}

//**************************************************************************************
MAP_errcode0 = new Array(
		  new Option("Data Missing (35)", "35")
		, new Option("Roaming not Allowed (8)", "8")
		, new Option("System Failure (34)", "34")
		, new Option("Unexpected Data Value (36)", "36")
	); 
MAP_errcode1 = new Array(
		  new Option("Disabled (0)", "0")
		,  new Option("Data Missing (35)", "35")
		, new Option("Roaming not Allowed (8)", "8")
		, new Option("System Failure (34)", "34")
		, new Option("Unexpected Data Value (36)", "36")
	); 

//**************************************************************************************
// tipoST_OP = 1 presteering
// tipoST_OP = 0 Operatori
//**************************************************************************************
function Insert_MAP_errcode(id, tipoST_OP)
{
	var MAP = eval('MAP_errcode' + tipoST_OP);

	document.inputform.MAP_ERR.length = MAP.length;
	for(i = 0; i< MAP.length; i++)
	{
		document.inputform.MAP_ERR.options[i] = MAP[i];
		//setto  default
		
		if (tipoST_OP == 1 && document.inputform.MAP_ERR.options[i].value == "8")
			document.inputform.MAP_ERR.options[i].selected = true;
		if (tipoST_OP == 0 && document.inputform.MAP_ERR.options[i].value == "36")
			document.inputform.MAP_ERR.options[i].selected = true;
	}
	
	for(i = 0; i< MAP.length; i++)
	{
		if(document.inputform.MAP_ERR.options[i].value == id)
		{
			document.inputform.MAP_ERR.options[i].selected = true;
			break;
		}
	}
}

//**************************************************************************************
LTE_errcode0 = new Array(
		  new Option("Roaming not Allowed (5004)", "5004")
		, new Option("Unable to comply (5012)", "5012")
	); 
LTE_errcode1 = new Array(
		  new Option("Disabled (0)", "0")
		, new Option("Roaming not Allowed (5004)", "5004")
		, new Option("Unable to comply (5012)", "5012")
	); 

//**************************************************************************************
// tipoST_OP = 1 presteering
// tipoST_OP = 0 Operatori
//**************************************************************************************
function Insert_LTE_errcode(id, tipoST_OP)
{
	var LTE = eval('LTE_errcode' + tipoST_OP);

	document.inputform.LTE_ERR.length = LTE.length;
	for(i = 0; i< LTE.length; i++)
	{
		document.inputform.LTE_ERR.options[i] = LTE[i];
		//setto default
		
		if (tipoST_OP == 1 && document.inputform.LTE_ERR.options[i].value == "5004")
			document.inputform.LTE_ERR.options[i].selected = true;
		if (tipoST_OP == 0 && document.inputform.LTE_ERR.options[i].value == "5012")
			document.inputform.LTE_ERR.options[i].selected = true;
	}
	
	for(i = 0; i< LTE.length; i++)
	{
		if(document.inputform.LTE_ERR.options[i].value == id)
		{
			document.inputform.LTE_ERR.options[i].selected = true;
			break;
		}
	}
}

//**************************************************************************************
Border_strategy = new Array(
		  new Option("Disabled (0)", "0")
		, new Option("Sms Alert (1)", "1")
		, new Option("Deny always (2)", "2")
	); 
//**************************************************************************************
function Insert_Border_strategy(id)
{
	var Bord = document.inputform.BORD_ROAM;
	Bord.length = Border_strategy.length;
	for(i = 0; i< Border_strategy.length; i++)
	{
		Bord.options[i] = Border_strategy[i];
		if(Border_strategy[i].value == id)
			Bord.options[i].selected = true;
	}
}
//**************************************************************************************

function setImpianti() {
  document.inputform.ImpiantiSelect.length = aImpianti.length;
  for (i=0; i<aImpianti.length; i++)
    document.inputform.ImpiantiSelect.options[i] = aImpianti[i];
}

function setMgt(ctry) 
{
	with (document.inputform) 
	{
		for(var i=(MGTSelect.length-1); i>=0; i--)
			MGTSelect.options[i]=null;
		var k = -1;
		for (i=0; i<aMgt[ctry].length; i++) 
		{
			MGTSelect.options[++k] = aMgt[ctry][i];
		}
		MGTSelect.selectedIndex = 0;
	 }
}

function setVLR(cop) 
{
	var selPA =  document.inputform.countrySelect.selectedIndex;

	
	//solo se è stato selezionato un operatore
	if(document.inputform.operatorSelect.options.selectedIndex > 0) 	
	{
		with (document.inputform) 
		{
			for(var i=(VLRSelect.length-1); i>=0; i--)
				VLRSelect.options[i]=null;
			var k = -1;
			for (i=0; i<aGTOP[selPA][cop-1].length; i++) 
			{
				VLRSelect.options[++k] = aGTOP[selPA][cop-1][i];
			}
			VLRSelect.selectedIndex = 0;
			VLRPostfix.value = "";
			$('.chosen-select').trigger("chosen:updated");	 
		}
	}
}


// Lista gruppi Operatori x Inserimento Soglie
 function setGRPOP() 
 {
	document.inputform.GroupOPSelect.length = aGROperatori.length;
	for (i=0; i<aGROperatori.length; i++)
		document.inputform.GroupOPSelect.options[i] = aGROperatori[i];
}
// Lista gruppi Paesi x Inserimento Soglie
 function setGRPPA() 
 {
	document.inputform.GroupPASelect.length = aGRPaesi.length;
	for (i=0; i<aGRPaesi.length; i++)
		document.inputform.GroupPASelect.options[i] = aGRPaesi[i];
}

function abilita_campi(tipo)
{
	if(tipo == 0) //onchange del country
	{
		if(document.inputform.countrySelect.options.selectedIndex != 0)
		{
		//	document.inputform.GroupOPSelect.disabled = true;
		//	document.inputform.GroupPASelect.disabled = true;
			document.inputform.GroupOPSelect.setAttribute("disabled","disabled");
			document.inputform.GroupPASelect.setAttribute("disabled","disabled");
		
			//document.inputform.GroupPASelect.chosen.prop('disabled', true);
			//document.inputform.GroupOPSelect.chosen.prop('disabled', true);
			 $("#grp").prop('disabled',true).trigger("chosen:updated");
			 $("#grp2").prop('disabled',true).trigger("chosen:updated");
			 
			// $("#cc_co").trigger("chosen:updated");
		}
		else
		{
		//	document.inputform.GroupOPSelect.disabled = false;
		//	document.inputform.GroupPASelect.disabled = false;
			document.inputform.GroupOPSelect.removeAttribute("disabled");
			document.inputform.GroupPASelect.removeAttribute("disabled");
	
			//document.inputform.GroupPASelect.chosen.prop('disabled', false);
			//document.inputform.GroupOPSelect.chosen.prop('disabled', false);
			
			$("#grp").prop('disabled',false).trigger("chosen:updated");
			$("#grp2").prop('disabled',false).trigger("chosen:updated");
			
		}
	}
	else if(tipo == 1) //onchange dei Gruppi
	{
		if((document.inputform.GroupOPSelect.options.selectedIndex != 0 ) ||
			(document.inputform.GroupPASelect.options.selectedIndex != 0) )
		{
			document.inputform.countrySelect.disabled = true;
			document.inputform.operatorSelect.disabled = true;
		    $("#cc_co").prop('disabled',true).trigger("chosen:updated");
			
		}
		else
		{
			document.inputform.countrySelect.disabled = false;
			document.inputform.operatorSelect.disabled = false;
		    $("#cc_co").prop('disabled',false).trigger("chosen:updated");
			
		}
	}
}
//************************************
function setFiltroPA(ctry) 
{
 with (document.inputform) 
 {
	for(var i=(operatorSelect.length-1); i>=0; i--)
		operatorSelect.options[i]=null;
	StringToSearch=new String(fPaesi.value);
	var k = -1;
	for (i=0; i<listaPaesi.length; i++) 
	{
		var s = new String(listaPaesi[i].text);
		if (StringToSearch != "") 
		{
			if ( s.toUpperCase().indexOf(StringToSearch.toUpperCase()) != -1 )
				operatorSelect.options[++k] = listaPaesi[i];
		} else operatorSelect.options[++k] = listaPaesi[i];
	}
	operatorSelect.selectedIndex = -1;
  }
}
//**************************************************************************************************************

function CheckGroupName(operType)
{
	if (operType == 1) //insert
	{
		if (document.inputform.GRUPPO.value == "" )
		{
			alert("Group Name is mandatory");
			document.inputform.GRUPPO.focus()
			return false;
		}		
	}
}
function CheckLte(indice)
{
	if(document.inputform.ImpiantiSelect.options[indice].value == '----')
	{
		document.inputform.LTE.checked = true;
	}
}

//*********************************************************************
//display user
function userType(id)
{
	var usertList = new Array("Postpaid BU", "Postpaid CO", "Prepaid CO domiciled",
						"Prepaid CO NOT domiciled", "Prepaid BU", "TOP", "Profile blocked",
						"Profile indefinite", "Prepaid"); 
						
	document.write(usertList[id]);
}

//display  list operators
Opers = new Array(
		   new Option("TIM", "0")
		  ,new Option("COOP", "A") 
		  ,new Option("TISCALI", "B") 
		  ,new Option("MTV", "C") 
		  ,new Option("NOVERCA", "D")   
		  ,new Option("    ", " ", true)   		   
); 
function List_Opers(id, campo)
{
	nome_sel = eval("document." + campo);
	nome_sel.length = Opers.length;
	for(i = 0; i< Opers.length; i++)
	{
		nome_sel.options[i] = Opers[i];
		if (nome_sel.options[i].value == " ")
			nome_sel.options[i].selected = true;
	}
	for(i = 0; i< Opers.length; i++)
	{
		if(nome_sel.options[i].value == id )
		{
			nome_sel.options[i].selected = true;
			break;
		}
	}
}

//********************************************
function openWin() 
{
	myWindow = window.open("country_operator_group_upd.cgi?OPERATION=Update&ALTRA-CGI=Y", "myWindow");    // Opens a new window
	
}

//**************************************************************************************************
//      func GTT Csend command
//**************************************************************************************************
function Select_All(valore)
{
	document.insert.CPU00.checked=valore;
	document.insert.CPU01.checked=valore;
	document.insert.CPU02.checked=valore;
	document.insert.CPU03.checked=valore;
	document.insert.CPU04.checked=valore;
	document.insert.CPU05.checked=valore;
	document.insert.CPU06.checked=valore;
	document.insert.CPU07.checked=valore;
	document.insert.CPU08.checked=valore;
	document.insert.CPU09.checked=valore;
	document.insert.CPU10.checked=valore;
	document.insert.CPU11.checked=valore;
	document.insert.CPU12.checked=valore;
	document.insert.CPU13.checked=valore;
	document.insert.CPU14.checked=valore;
	document.insert.CPU15.checked=valore;
}
function Controlla()
{
	// trim dei campi
	document.insert.TASKID.value = trim(document.insert.TASKID.value);
	document.insert.SRVCLS.value = trim(document.insert.SRVCLS.value);
	if (document.insert.TASKID.value.length == 0)
	{
		alert('Fill TASK ID');			
		document.insert.TASKID.focus();	
		return false;
	}
	if (document.insert.SRVCLS.value.length == 0)
	{
		alert('Fill SERVER CLASS');		
		document.insert.SRVCLS.focus();	
		return false;
	}
	a = document.insert.CPU01.checked || document.insert.CPU02.checked || document.insert.CPU03.checked || document.insert.CPU04.checked;		
	a = a || document.insert.CPU05.checked || document.insert.CPU06.checked || document.insert.CPU07.checked || document.insert.CPU08.checked;	
	a = a || document.insert.CPU09.checked || document.insert.CPU10.checked || document.insert.CPU11.checked || document.insert.CPU12.checked;	
	a = a || document.insert.CPU13.checked || document.insert.CPU14.checked || document.insert.CPU15.checked || document.insert.CPU00.checked;	
	if (a == false)	
	{
		alert('Select 1 CPU at least');	
		return false;
	}
	return true;	
}
//**************************************************************************************************
function addOpinGRP(all) 
{
  var a = new Boolean();
 if (all == "true") a=true; else a=false;
 with (document.inputform) 
 {
   if (countrySelect.options[countrySelect.selectedIndex].value=="ALL") return;
   
   var i;
   for(i=0; i<operatorSelect.length; i++) 
   {
		if ((operatorSelect.options[i].selected == true) || (a == true)) 
		{
			j=0;
			while ( j>=0 && j<operatorSelected.length ) 
			{
				//prendi tuuto quello che ha un car corrispondente a [ seguito da qualsiai cosa seguita da ]
				//seguito da car space o _ da 0 infinite volte 
				// torna array elem 0 stringo orig elemento 1 2 ecc dipende da ciò che è compreso tra tonde 
				//(es: /a(.*)b/   str aciaob -> ciao ahellok -> "" perchè non fa match
				var reg_exp = new RegExp ( /[\[](.*)[\]][ .]*(.*)/ );
				var appo = operatorSelected.options[j].text;
				var aRis = appo.match(reg_exp);
				if((aRis[1] == countrySelect.options[countrySelect.selectedIndex].text) && (aRis[2] == operatorSelect.options[i].text))
					j=-1;
				else ++j;
			}
			if (j>=0) 
			{
				operatorSelected.length = operatorSelected.length+1;
				operatorSelected.options[operatorSelected.length-1] = new Option("["+ countrySelect.options[countrySelect.selectedIndex].text +"] "+ operatorSelect.options[i].text ,operatorSelect.options[i].value);
				var ctrId = ((operatorSelected.options[operatorSelected.length-1].value).substring(0,3)).replace(/^\s*|\s*$/g,"");
				for(k=operatorSelected.length-2; k>=0; k--) 
				{
					if (((operatorSelected.options[k].value).substring(0,3)).replace(/^\s*|\s*$/g,"") == ctrId) 
					{
						moveOperatorTo(k+1);
						break;
					}
				}
			}    
		} 
	} 
  }  
	normalizzaOption(document.inputform.operatorSelected);
}
// *****************************************************************************	
function addPaesi_inGRP(all) 
{
 var a = new Boolean();
 if (all == "true") a=true; else a=false;
 with (document.inputform) 
 {
  
   var i;
   for(i=0; i<operatorSelect.length; i++) 
   {
		if ((operatorSelect.options[i].selected == true) || (a == true)) 
		{
			j=0;
			while ( j>=0 && j<operatorSelected.length ) 
			{
				//prendi tuuto quello che ha un car corrispondente a [ seguito da qualsiai cosa seguita da ]
				//seguito da car space o _ da 0 infinite volte 
				// torna array elem 0 stringo orig elemento 1 2 ecc dipende da ciò che è compreso tra tonde 
				//(es: /a(.*)b/   str aciaob -> ciao ahellok -> "" perchè non fa match
				//var reg_exp = new RegExp ( /[\[](.*)[\]][ .]*(.*)/ );
				var appo = operatorSelected.options[j].text;
				//var aRis = appo.match(reg_exp);
				//if((aRis[1] == operatorSelect.options[i].text))
				if((appo == operatorSelect.options[i].text))
					j=-1;
				else ++j;
			}
			if (j>=0) 
			{
				operatorSelected.length = operatorSelected.length+1;
				operatorSelected.options[operatorSelected.length-1] = new Option( operatorSelect.options[i].text ,operatorSelect.options[i].value);
				var ctrId = ((operatorSelected.options[operatorSelected.length-1].value)).replace(/^\s*|\s*$/g,"");
				for(k=operatorSelected.length-2; k>=0; k--) 
				{
					if (((operatorSelected.options[k].value)).replace(/^\s*|\s*$/g,"") == ctrId) 
					{
						moveOperatorTo(k+1);
						break;
					}
				}
			}    
		} 
	} 
  }  
//	normalizzaOption(document.inputform.operatorSelected);
}
//*********************************************************************************************
function moveOperatorTo(idx) {
  with (document.inputform.operatorSelected) {
    var i;
    for(i=length-1; i>idx; i--) {
      options[i].selected=true;
      moveOperator(0);
      selectedIndex=-1;
    }      }}

function delOperators() {
 with (document.inputform.operatorSelected) {
  for(i=0; i<length; i++) {
    if (options[i].selected == true) {
      j=i;
      while ( j<length-1 ) {
  	options[j] = new Option(options[j+1].text,options[j+1].value);
  	options[j].selected = options[j+1].selected;
	++j;
      }
      options[length-1] = null;
      --i;
    }  }  selectedIndex = -1; }
	
		//id_tot.innerText = document.inputform.operatorSelected.length;
	}

function delAllOperators() {

 with (document.inputform.operatorSelected) {
  for(i=0; i<length; i++) {
    j=i;
    while ( j<length-1 ) {
      options[j] = new Option(options[j+1].text,options[j+1].value);
      ++j;
    }
    options[length-1] = null;
    --i;
  }  selectedIndex = -1; }

	//id_tot.innerText = document.inputform.operatorSelected.length;

  }function setListaDB() 
 {
  document.inputform.operatorSelected.length = listaDB.length;
  for (i=0; i<listaDB.length; i++)
    document.inputform.operatorSelected.options[i] = listaDB[i];

  //id_tot.innerText = document.inputform.operatorSelected.length;
}
 function setListaPaesi() 
 {
  document.inputform.operatorSelect.length = listaPaesi.length;
  for (i=0; i<listaPaesi.length; i++)
    document.inputform.operatorSelect.options[i] = listaPaesi[i];
}


function normalizzaOption(obj_select)
{
//   alert( "IN normalizzaOption");
//   alert("obj_select length:"+obj_select.length);
   // lunghezza max
   var reg_exp = new RegExp ( /([\[].*[\]])[ .]*(.*)/ );
//   alert("obj_select length:"+obj_select.length);
   var a; 
   var max_l=0;
   for (a=0; a < obj_select.length; a++)
   {
//      alert(a+")"+"obj_select:"+obj_select.options[a].text);
      var arr = obj_select.options[a].text.match(reg_exp);
      // debug !
      //var b;
      //for ( b=0; b< arr.length ; b++)
      //{
      //   alert( "arr:"+arr[b] );
      //}
      if ( max_l < arr[1].length ) { max_l = arr[1].length; }
   }
//   alert( "max_l:"+max_l );
   
      
   for (a=0; a < obj_select.length; a++)
   {
      var s="................................................";   
        
//      alert("prima obj_select:"+obj_select.options[a].text);
      var arr = obj_select.options[a].text.match(reg_exp);
      s=s.substring(arr[1].length,max_l);      
//      alert("s:"+s.length+":");
      s = arr[1] + s +" "+ arr[2] ;
      
      //obj_select.options[a].value = s ;
      obj_select.options[a].text  = s ;

      
//      alert("dopo obj_select:"+obj_select.options[a].text);
//      alert("dopo obj_select:"+obj_select.options[a].text.length);
                                    
   }
//   alert( "OUT normalizzaOption");
}

//*******************************************************************************************  

function moveOperator(drt) 
{
	 with (document.inputform.operatorSelected) 
	{
	  var j = selectedIndex;
	  var k = length;

  if (j<0) return;

  // move selected operator up

  if (drt==0) {      if (j<=0) return;
    var opt = new Option(options[j-1].text,options[j-1].value);
    options[j-1] = new Option(options[j].text,options[j].value);
    options[j] = new Option(opt.text,opt.value);
    opt = null;
    selectedIndex=j-1;
    return;

  // move selected operator down
  } else if (drt==1) { if (j>=k-1) return;

    var opt = new Option(options[j+1].text,options[j+1].value);
    options[j+1] = new Option(options[j].text,options[j].value);
    options[j] = new Option(opt.text,opt.value);
    opt = null;
    selectedIndex=j+1;
    return;

  // move selected operator to Top
  } else if (drt==2) { if (j<=0) return;

    for (i=j; i>0; i--) {
      var opt = new Option(options[i-1].text,options[i-1].value);
      options[i-1] = new Option(options[i].text,options[i].value);
      options[i] = new Option(opt.text,opt.value);
      opt = null;
    }

    selectedIndex=0;
    return;
 
  // move selected operator to Bottom
  } else if (drt==3) { if (j>=k-1) return;
    for (i=0; i<k-1; i++) {
      var opt = new Option(options[i+1].text,options[i+1].value);
      options[i+1] = new Option(options[i].text,options[i].value);
      options[i] = new Option(opt.text,opt.value);
      opt = null;
    }
    selectedIndex=k-1;
    return; 
    }       }}


function setBackgroundColor() {
  if (document.all)
    for (var i=0; i < document.all.length; i++)
      if (
          (document.all[i].type == 'select-multiple') ||
          (document.all[i].type == 'select-one') ||
          (document.all[i].type == 'text')
         )
          document.all[i].style.background = '#ffffff';
}

//***************************************************************************************
// MGT_I serve in modifica perchè JS non vede i campi <input type HIDDEN>
//***************************************************************************************
function check_range_MGT(tipo, MGT_I) {

var value_mgt_inizio = trim( document.inputform.MGT.value );
var value_mgt_fine =  trim( document.inputform.MGT_END.value );

	if(tipo == 1)  // inserimento
	{
		if( value_mgt_inizio == "" || value_mgt_inizio == 0) 
		{
			alert("MGT Start is mandatory and the value must be > 0");
			document.inputform.MGT.focus();
			return false;
		}
	}
	else  //modifica
		value_mgt_inizio = parseInt(trim(MGT_I));
	
	if(value_mgt_fine == "" || value_mgt_fine == 0) 
	{
		alert("MGT End is mandatory and the value must be > 0");
		document.inputform.MGT_END.focus();
		return false;
	}

	if( parseInt(value_mgt_inizio) > parseInt(value_mgt_fine) )
	{
		alert("MGT Start is bigger then MGT End ");
		document.inputform.MGT_END.focus();
		return false;
	}
	
	return true;	
}

function check_MGT(tipo) {

	if(tipo == 1)
	{
		if(trim( document.inputform.MGT.value ) == "") 
		{
			alert("MGT Start is mandatory");
			document.inputform.MGT.focus();
			return false;
		}
	}
	
	return true;	
}

function checkHomeNet(tipo)
{
	if(tipo == 1)
	{
		if(trim( document.inputform.LAC.value ) == "" || (document.inputform.LAC.value ) == 0 ) 
		{
			alert("LAC is mandatory");
			document.inputform.LAC.focus();
			return false;
		}
		
		if( document.inputform.LAC.value  > 65535 ) 
		{
			alert("Max Value: 65535");
			document.inputform.LAC.focus();
			return false;
		}
		
		if( document.inputform.CELL.value  > 65535 ) 
		{
			alert("Max Value: 65535");
			document.inputform.CELL.focus();
			return false;
		}
	}
	
	return true;	
}