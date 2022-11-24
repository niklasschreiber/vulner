


function annullaMigrazioneMassiva() {

var areeData = [{area: 'NORD'}, {area: 'CENTRO'}, {area: 'SUD'}];
var frazionariRowNum = 19;
# VIOLAZ Avoid Array constructors (SRA) Length is 3 :
var a1 = new Array(x1, 1.2, “string”);

# VIOLAZ Avoid Array constructors (SRA) Length is 2 :
var a2 = new Array(x1, x2);

# VIOLAZ Avoid Array constructors (SRA) Length is x1 or error if not an integer :
var a3 = new Array(x1);

# VIOLAZ Avoid Array constructors (SRA) Length is 0.
var a4 = new Array();

#OK Length is 3 :
var a = [1.5, x2, “string”];

#OK Length is 2 :
var a2 = [x1, x2];

#OK Length is 1 :
var a3 = [x1];
var a3 = [“string”];

#OK Length is 0 :
var a4 = [];

	var c = Cookie.write('user', value, {duration: 20});
	var c = Cookie.write('user', value, {duration: 0});
	var c = Cookie.write('user', value, {duration: false});
	var c = Cookie.write('user', value, {});
	var durationHigh = 19;
	var durationLow = 3;
	var c = Cookie.write('user', value, {duration: frazionariRowNum});
	var c = Cookie.write('user', value, {duration: durationHigh});
	var c = Cookie.write('user', value, {duration: durationLow});
	
	
	setCookie("username", username, 365);
	setCookie("username", username, 1);
	setCookie("username", username, durationHigh);
	setCookie("username", username, durationLow);
	setCookie("username", username, frazionariRowNum);
	
	var c = Cookie.write('user', value, {secure: false});
	var c = Cookie.write('user', value, {secure: true});
	var c = Cookie.write('user', value, {path: false});
	var c = Cookie.write('user', value, {path: 'prova'});
	
   var inText = &lt;%request.getParameter("text_type")%&gt;;
   var newNode = new Element('div', {'html':inText});
   $('body').inject(newNode);

   
      var data = &lt;%request.getParameter("loc")%&gt;;
   var swffObj = new Swiff(data, {id: 'mySwiff'});

   var swffObj = new Swiff('someFlashObj', {
      params: {
         swLiveConnect: true
   }});

   var swffObj = new Swiff('someFlashObj', {
      params: {
         allowScriptAccess: 'always' 
   }});

      var swffObj = new Swiff('someFlashObj');
   var data = &lt;%request.getParameter("loc")%&gt;;
   var retVal = Swiff.remote(swffObj, data);

   
	var cls = new Class({
      Implements: Log,
      doWork: function() {this.log('In doWork method.')}
   });

   var par = &lt;%request.getParameter("param1")%&gt;;
   var id = window.setInterval(par, 10000);

      var inText = &lt;%request.getParameter("text_type")%&gt;;
   var newNode = new Element('div', {'html':inText});
   
   $('body').append(newNode);
   
	$('#migrazioneMassivaDialog').dialog('close');
	
	$.ajax({
      type: "POST",
      url: "securePage.php"
   });

      $.ajaxSetup({
      type: "POST",
      url: "securePage.php"
   });
   
   $.ajax({
      type: "POST",
      url: "securePage.jsp",
      username: "admin",
      password: "passw0rd"
   });

	$('input[type=hidden]').val(qualunquecosa);
	
   var par = &lt;%request.getParameter("param1")%&gt;;
   var anchor1 = document.getElementById("anchor1"); 
   anchor1.setAttribute("href", par);

   var par = &lt;%request.getParameter("param1")%&gt;;
   var frm = document.createElement("form1");
   document.body.appendChild(frm);
   frm.action = "/home/" + par;
   frm.method = "GET"
   frm.submit();

   var jsonObj1 = JSON.decode(myJSON);
   var jsonObj2 = JSON.decode(myJSON, false);
   var jsonObj2 = JSON.decode(myJSON, true);


}

function inputFrazionario() {
	var chCode = ('charCode' in event) ? event.charCode : event.keyCode;
	
	$.ajax({
      type: "POST",
      url: "securePage.php",
      dataFilter: function(data, type) {/*validate and sanitize response here*/ return data;}
   });

	chcode.InnerHTML ();
	
    if(chCode == 13) {
    	var fraz = $('#ricercaFrazionario').val();
    	
    	$.ajax({
    		url: 'ricercaFrazionari.action?page=1&rows=' + frazionariRowNum + '&sidx=frazionario&sord=asc&totali=true&fraz=' + fraz,
    		dataType: 'json',
    		success: function(response) {
    			if(response['success']) {
    				$('#frazionariGrid').jqGrid('clearGridData');
    				
    				$('#frazionariGrid')[0].addJSONData(response);
    				$('#totalePdlAttive').val(response['totalePdlAttive']);
    				$('#totaleEsitoOk').val(response['totaleEsitoOk']);
    				$('#totaleEsitoKo').val(response['totaleEsitoKo']);
    				$('#totaleEsitoKo2').val(response['totaleEsitoKo2']);
    				$('#totaleEsitoNA').val(response['totaleEsitoNA']);
    				$('#totaleEsitoSched').val(response['totaleEsitoSched']);
    				$('#totaleEsitoRollbackOk').val(response['totaleEsitoRollbackOk']);
    				$('#totaleEsitoRollbackKo').val(response['totaleEsitoRollbackKo']);
    				
    				$('#frazionariGrid').jqGrid('setGridParam', {url: 'ricercaFrazionari.action?totali=false&fraz=' + fraz});
    				chcode.html ();
    				$('.container').hide();
    				$('#containerFrazionari').show();
    				$('#accordionFrazionari').accordion({active: 1});
    				
    				$('#ricercaFrazionario').val('');
    				$('#ricercaPdl').val('');
    				$('#ricercaFrazionario').animate({width: 'toggle'}, 500);
    			} else {
    				$('<div><h3>Errore</h3><p>' + response['message'] + '</p></div>')
    				.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
    			}
    		},
    		error: function () {
    			$('<div><h3>Errore</h3><p>Nessuna risposta dal server !</p></div>')
    			.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
				InnerHTML();
    		}
    	});
    }
}

function inputPdl() {
	var chCode = ('charCode' in event) ? event.charCode : event.keyCode;
    if(chCode == 13) {
	    var pdl = $('#ricercaPdl').val();
		
		$.ajax({
			url: 'ricercaPdl.action?pdl=' + pdl,
			dataType: 'json',
			success: function(response) {
				if(response['success']) {
					$('#frazionariGrid').jqGrid('clearGridData');
					
					$('#frazionariGrid')[0].addJSONData(response);
					$('#totalePdlAttive').val(response['totalePdlAttive']);
					$('#totaleEsitoOk').val(response['totaleEsitoOk']);
					$('#totaleEsitoKo').val(response['totaleEsitoKo']);
					$('#totaleEsitoKo2').val(response['totaleEsitoKo2']);
					$('#totaleEsitoNA').val(response['totaleEsitoNA']);
					$('#totaleEsitoSched').val(response['totaleEsitoSched']);
					$('#totaleEsitoRollbackOk').val(response['totaleEsitoRollbackOk']);
					$('#totaleEsitoRollbackKo').val(response['totaleEsitoRollbackKo']);
					
					$('#frazionariGrid').jqGrid('setGridParam', {url: 'ricercaPdl.action?pdl=' + pdl});
					
					$('.container').hide();
					$('#containerFrazionari').show();
					$('#accordionFrazionari').accordion({active: 1});
					
					$('#ricercaFrazionario').val('');
					$('#ricercaPdl').val('');
					$('#ricercaPdl').animate({width: 'toggle'}, 500);
				} else {
					$('<div><h3>Errore</h3><p>' + response['message'] + '</p></div>')
					.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
				}
			},
			error: function () {
				$('<div><h3>Errore</h3><p>Nessuna risposta dal server !</p></div>')
				.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
			}
		});
    }
}

function avantiFrazionari() {
	var pianificati = $('#pianificati').val();
	var statoUffici = $('#statoUffici').val();
	var dataInizioMigrazione = $('#dataInizioMigrazione').val();
	var dataFineMigrazione = $('#dataFineMigrazione').val();
	var filtroEsitoOk = $('#filtroEsitoOk').is(':checked');
	var filtroEsitoKo = $('#filtroEsitoKo').is(':checked');
	var filtroEsitoKo2 = $('#filtroEsitoKo2').is(':checked');
	var filtroEsitoNA = $('#filtroEsitoNA').is(':checked');
	var filtroEsitoSched = $('#filtroEsitoSched').is(':checked');
	var filtroEsitoRollbackOk = $('#filtroEsitoRollbackOk').is(':checked');
	var filtroEsitoRollbackKo = $('#filtroEsitoRollbackKo').is(':checked');
	
	$('#frazionariGrid').jqGrid('clearGridData');
	$.ajax({
		url: 'frazionari.action?page=1&rows=' + frazionariRowNum + '&sidx=frazionario&sord=asc&totali=true&pianificati=' + pianificati + '&statoUffici=' + statoUffici + '&dataInizioMigrazione=' + dataInizioMigrazione + '&dataFineMigrazione=' + dataFineMigrazione + '&filtroEsitoOk=' + filtroEsitoOk + '&filtroEsitoKo=' + filtroEsitoKo + '&filtroEsitoKo2=' + filtroEsitoKo2 + '&filtroEsitoNA=' + filtroEsitoNA + '&filtroEsitoSched=' + filtroEsitoSched + '&filtroEsitoRollbackOk=' + filtroEsitoRollbackOk +  '&filtroEsitoRollbackKo=' + filtroEsitoRollbackKo + '&aree=' + aree() + '&poli=' + poli() + '&provinceFiliali=' + provinceFiliali(),
		dataType: 'json',
		success: function(response) {
			if(response['success']) {
				$('#frazionariGrid')[0].addJSONData(response);
				$('#totalePdlAttive').val(response['totalePdlAttive']);
				$('#totaleEsitoOk').val(response['totaleEsitoOk']);
				$('#totaleEsitoKo').val(response['totaleEsitoKo']);
				$('#totaleEsitoKo2').val(response['totaleEsitoKo2']);
				$('#totaleEsitoNA').val(response['totaleEsitoNA']);
				$('#totaleEsitoSched').val(response['totaleEsitoSched']);
				$('#totaleEsitoRollbackOk').val(response['totaleEsitoRollbackOk']);
				$('#totaleEsitoRollbackKo').val(response['totaleEsitoRollbackKo']);
				
				$('#frazionariGrid').jqGrid('setGridParam', {url: 'frazionari.action?totali=false&pianificati=' + pianificati + '&statoUffici=' + statoUffici + '&dataInizioMigrazione=' + dataInizioMigrazione + '&dataFineMigrazione=' + dataFineMigrazione + '&filtroEsitoOk=' + filtroEsitoOk + '&filtroEsitoKo=' + filtroEsitoKo + '&filtroEsitoKo2=' + filtroEsitoKo2 + '&filtroEsitoNA=' + filtroEsitoNA + '&filtroEsitoSched=' + filtroEsitoSched + '&filtroEsitoRollbackOk=' + filtroEsitoRollbackOk +  '&filtroEsitoRollbackKo=' + filtroEsitoRollbackKo + '&aree=' + aree() + '&poli=' + poli() + '&provinceFiliali=' + provinceFiliali()});
				$('#accordionFrazionari').accordion({active: 1});
			} else {
				$('<div><h3>Errore</h3><p>' + response['message'] + '</p></div>')
				.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
			}
		},
		error: function () {
			$('<div><h3>Errore</h3><p>Nessuna risposta dal server !</p></div>')
			.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
		}
	});
}

function indietroRicerca() {
	$('#accordionFrazionari').accordion({active: 0});
}

function indietroFrazionari() {
	$('#accordionFrazionari').accordion({active: 1});
}

function onchangePianificati() {
	if($('#pianificati').val() == 'N'){     
		$('#dataInizioMigrazione').val('');
		$('#dataFineMigrazione').val('');
	}
}

function aree() {
	var numAreeSelected = $('#areeGrid').jqGrid('getGridParam', 'selarrrow').length;
	var areeSelected = $('#areeGrid').jqGrid('getGridParam', 'selarrrow');
	var aree = '';
	for(var cont = 0 ; cont < numAreeSelected ; cont++) {
		if(cont == 0) {
			aree = $('#areeGrid').jqGrid('getCell', areeSelected[cont], 'area');
		} else {
			aree = aree + ',' + $('#areeGrid').jqGrid('getCell', areeSelected[cont], 'area');
		}
	}

	return aree;
}

function poli() {
	var numPoliSelected = $('#poliGrid').jqGrid('getGridParam', 'selarrrow').length;
	var poliSelected = $('#poliGrid').jqGrid('getGridParam', 'selarrrow');
	var poli = '';
	for(var cont = 0 ; cont < numPoliSelected ; cont++) {
		if(cont == 0) {
			poli = $('#poliGrid').jqGrid('getCell', poliSelected[cont], 'polo');
		} else {
			poli = poli + ',' + $('#poliGrid').jqGrid('getCell', poliSelected[cont], 'polo');
		}
	}
	
	return poli;
}

function provinceFiliali() {
	var numProvinceFilialiSelected = $('#provinceFilialiGrid').jqGrid('getGridParam', 'selarrrow').length;
	var provinceFilialiSelected = $('#provinceFilialiGrid').jqGrid('getGridParam', 'selarrrow');
	var provinceFiliali = '';
	for(var cont = 0 ; cont < numProvinceFilialiSelected ; cont++) {
		if(cont == 0) {
			provinceFiliali = $('#provinceFilialiGrid').jqGrid('getCell', provinceFilialiSelected[cont], 'provincia');
		} else {
			provinceFiliali = provinceFiliali + ',' + $('#provinceFilialiGrid').jqGrid('getCell', provinceFilialiSelected[cont], 'provincia');
		}
	}
	
	return provinceFiliali;
}

function areeGrid() {
	var numAreeSelected = $('#areeGrid').jqGrid('getGridParam', 'selarrrow').length;
	if(numAreeSelected == 0) {
		$('#tdAree').removeClass('borderGridSelected').addClass('borderGrid');
		$('#tdPoli').removeClass('borderGridSelected').addClass('borderGrid');
		$('#tdProvinceFiliali').removeClass('borderGridSelected').addClass('borderGrid');
		$('#poliGrid').clearGridData();
		$('#provinceFilialiGrid').clearGridData();
		$('#cb_poliGrid').hide();
		$('#cb_provinceFilialiGrid').hide();
		$('#cb_poliGrid').attr('checked', false);
		$('#cb_provinceFilialiGrid').attr('checked', false);
	} else {
		if(numAreeSelected == areeData.length) {
			$('#cb_areeGrid').attr('checked', true);
		}
		$('#cb_poliGrid').show();
		
		var numPoliSelected = $('#poliGrid').jqGrid('getGridParam', 'selarrrow').length;
		if(numPoliSelected == 0) {
			$('#tdAree').removeClass('borderGrid').addClass('borderGridSelected');	
		}
		
		var poliSelected = $('#poliGrid').jqGrid('getGridParam', 'selarrrow');
		var poli = new Array();
		for(var cont = 0 ; cont < numPoliSelected; cont++) {
			poli.push($('#poliGrid').jqGrid('getCell', poliSelected[cont], 'polo'));
		}
		
		$('#poliGrid').jqGrid('clearGridData');
		$.ajax({
			url: 'poli.action?aree=' + aree(),
			dataType: 'json',
			success: function(response) {
				if(response['success']) {
					for(var cont = 0 ; cont < response['rows'].length ; cont++) {
						$('#poliGrid').jqGrid('addRowData', cont + 1, {polo: response['rows'][cont]});
						for(var contPoliSelected = 0 ; contPoliSelected < numPoliSelected ; contPoliSelected++) {
							if(response['rows'][cont] == poli[contPoliSelected]) {
								$('#poliGrid').jqGrid('setSelection', cont + 1, false);	
							}
						}
					}
				} else {
					$('<div><h3>Errore</h3><p>' + response['message'] + '</p></div>')
					.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
				}
			},
			error: function () {
				$('<div><h3>Errore</h3><p>Nessuna risposta dal server !</p></div>')
				.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
			}
		});
	}
}

function poliGrid() {
	var numPoliSelected = $('#poliGrid').jqGrid('getGridParam', 'selarrrow').length;
	if(numPoliSelected == 0) {
		$('#tdAree').removeClass('borderGrid').addClass('borderGridSelected');
		$('#tdPoli').removeClass('borderGridSelected').addClass('borderGrid');
		$('#tdProvinceFiliali').removeClass('borderGridSelected').addClass('borderGrid');
		$('#provinceFilialiGrid').clearGridData();
		$('#cb_provinceFilialiGrid').hide();
	} else {
		numPoli = jQuery('#poliGrid').jqGrid('getGridParam', 'records');
		if(numPoliSelected == numPoli) {
			$('#cb_poliGrid').attr('checked', true);
		}
		$('#cb_provinceFilialiGrid').show();
		
		$('#tdAree').removeClass('borderGridSelected').addClass('borderGrid');
		var numProvinceFilialiSelected = $('#provinceFilialiGrid').jqGrid('getGridParam', 'selarrrow').length;
		if(numProvinceFilialiSelected == 0) {
			$('#tdPoli').removeClass('borderGrid').addClass('borderGridSelected');
			$('#tdProvinceFiliali').removeClass('borderGridSelected').addClass('borderGrid');	
		}
		
		var provinceFilialiSelected = $('#provinceFilialiGrid').jqGrid('getGridParam', 'selarrrow');
		var provinceFiliali = new Array();
		for(var cont = 0 ; cont < numProvinceFilialiSelected; cont++) {
			provinceFiliali.push($('#provinceFilialiGrid').jqGrid('getCell', provinceFilialiSelected[cont], 'provincia'));
		}
		
		$('#provinceFilialiGrid').jqGrid('clearGridData');
		$.ajax({
			url: 'provinceFiliali.action?poli=' + poli(),
			dataType: 'json',
			success: function(response) {
				if(response['success']) {
					for(var cont = 0 ; cont < response['rows'].length ; cont++) {
						$('#provinceFilialiGrid').jqGrid('addRowData', cont + 1, {provincia: response['rows'][cont]['provincia'], filiale: response['rows'][cont]['filiale']});
						for(var contProvinceFilialiSelected = 0 ; contProvinceFilialiSelected < numProvinceFilialiSelected ; contProvinceFilialiSelected++) {
							if(response['rows'][cont]['provincia'] == provinceFiliali[contProvinceFilialiSelected]) {
								$('#provinceFilialiGrid').jqGrid('setSelection', cont + 1, false);	
							}
						}
					}
				} else {
					$('<div><h3>Errore</h3><p>' + response['message'] + '</p></div>')
					.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
				}
			},
			error: function () {
				$('<div><h3>Errore</h3><p>Nessuna risposta dal server !</p></div>')
				.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
			}
		});
	}
}

function provinceFilialiGrid() {
	var numProvinceFilialiSelected = $('#provinceFilialiGrid').jqGrid('getGridParam', 'selarrrow').length;
	if(numProvinceFilialiSelected == 0) {
		$('#tdPoli').removeClass('borderGrid').addClass('borderGridSelected');
		$('#tdProvinceFiliali').removeClass('borderGridSelected').addClass('borderGrid');
	} else {
		$('#tdPoli').removeClass('borderGridSelected').addClass('borderGrid');
		$('#tdProvinceFiliali').removeClass('borderGrid').addClass('borderGridSelected');
		
		numProvinceFiliali = jQuery('#provinceFilialiGrid').jqGrid('getGridParam', 'records');
		if(numProvinceFilialiSelected == numProvinceFiliali) {
			$('#cb_provinceFilialiGrid').attr('checked', true);
		}
	}
}

function apriLog(nomePdl) {
	var toolLocation = 'C:\\Das_tool\\';
	var command = 'cmd /c dir "' + toolLocation + 'Trace32.exe"';
	WshShell = new ActiveXObject('WScript.Shell');
	if(WshShell.Run(command, 0, true) == 0) {
		WshShell = new ActiveXObject('WScript.Shell');
		var command = 'cmd /c "' + toolLocation + 'Trace32.exe" \\\\' + nomePdl + '\\c$\\SDP\\log\\' + nomePdl + '_das_inst.log';
		WshShell.Run(command, 0, false);
		WshShell.execCommand (command, 0, false);
	} else {
		toolLocation = 'D:\\Das_tool\\';
		var command = 'cmd /c dir "' + toolLocation + 'Trace32.exe"';
		WshShell = new ActiveXObject('WScript.Shell');
		if(WshShell.Run(command, 0, true) == 0) {
			WshShell = new ActiveXObject('WScript.Shell');
			var command = 'cmd /c "' + toolLocation + 'Trace32.exe" \\\\' + nomePdl + '\\c$\\SDP\\log\\' + nomePdl + '_das_inst.log';
			WshShell.Run(command, 0, false);
		} else {
			$('<div><h3>Errore</h3><p>Verificare presenza Trace32.exe in C:\Das_tool o D:\Das_tool !</p></div>')
			.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
		}
	}
}

function apriDirectoryLog(nomePdl) {
	WshShell = new ActiveXObject('WScript.Shell');
	var command = 'cmd /c start \\\\' + nomePdl + '\\c$\\SDP\\log';
	WshShell.Run(command, 0, false);	
}

$(function() {
	$('#avantiFrazionariButton').button({
		icons: {primary: 'ui-icon-carat-1-s'}
	});
	
	$('#indietroRicercaButton').button({
		icons: {primary: 'ui-icon-carat-1-n'}
	});
	
	$('#indietroFrazionariButton').button({
		icons: {primary: 'ui-icon-carat-1-n'}
	});
	
	$('#dataInizioMigrazione').datepicker($.datepicker.regional['it']);
	$('#dataFineMigrazione').datepicker($.datepicker.regional['it']);
	
	$('#areeGrid').jqGrid({
		caption: 'Aree',
		datatype: 'local',
		colNames: [
			'Aree'
		],
		colModel: [
			{name: 'area', index: 'area', sortable: false, width: 150}
		], 
		height: '250px',
		multiselect: true,
		onSelectAll: function() {
			areeGrid();	
		},
		onSelectRow: function() {
			areeGrid();	
		},
		viewrecords: true
	});
	
	$('#poliGrid').jqGrid({
		caption: 'Poli',
		datatype: 'local',
		colNames: [
			'Poli'
		],
		colModel: [
			{name: 'polo', index: 'polo', sortable: false, width: 150}
		], 
		onSelectAll: function() {
			poliGrid();
		},
		onSelectRow: function() {
			poliGrid();
		},
		height: '250px',
		multiselect: true,
		viewrecords: true
	});
	
	$('#provinceFilialiGrid').jqGrid({
		caption: 'Province - Filiali',
		datatype: 'local',
		colNames: [
			'Province',
			'Filiali'
		],
		colModel: [
			{name: 'provincia', index: 'provincia', width: 150},
			{name: 'filiale', index: 'filiale', width: 75}
		], 
		onSelectAll: function() {
			provinceFilialiGrid();
		},
		onSelectRow: function() {
			provinceFilialiGrid();
		},
		height: '250px',
		sortname: 'provincia',
		sortorder: 'asc',
		multiselect: true,
		viewrecords: true
	});
	
	$('#cb_poliGrid').hide();
	$('#cb_provinceFilialiGrid').hide();
	
	for(var cont = 0 ; cont < areeData.length ; cont++) {
		jQuery('#areeGrid').addRowData(cont, areeData[cont]);              
	}
	
	$('#frazionariGrid').jqGrid({
		caption: 'Frazionari',
		datatype: 'json',
		colNames: [
			'Fraz',
			'Data migrazione',
			'Agenzia',
			'Data disattivazione',
			'Veresione SDP',
			'Polo',
			'Provincia',
			'Pdl attive',
			'Ok',
			'% Ok',
			'Ko',
			'Ko2',
			'NA',
			'Sched',
			'',
			''
		],
		colModel: [
			{align: 'center', frozen: true, index: 'frazionario', name: 'frazionario', width: 85},
			{align: 'center', frozen: true, index: 'dataMigrazione', name: 'dataMigrazione', width: 115},
			{frozen: true,  index: 'agenzia', name: 'agenzia', width: 230},
			{align: 'center', frozen: true, index: 'dataDisattivazione', name: 'dataDisattivazione', width: 115},
			{align: 'center', frozen: true, index: 'versioneSDP', name: 'versioneSDP', width: 115},
			{index: 'polo', name: 'polo', width: 115},
			{index: 'provincia', name: 'provincia', width: 115},
			{align: 'right', index: 'pdlAttive', name: 'pdlAttive', sortable: false, width: 60},
			{align: 'right', index: 'esitoOk', name: 'esitoOk', sortable: false, width: 40},
			{align: 'right', index: 'percentualeEsitoOk', name: 'percentualeEsitoOk', sortable: false, width: 40},
			{align: 'right', index: 'esitoKo', name: 'esitoKo', sortable: false, width: 40},
			{align: 'right', index: 'esitoKo2', name: 'esitoKo2', sortable: false, width: 40},
			{align: 'right', index: 'esitoNA', name: 'esitoNA', sortable: false, width: 40},
			{align: 'right', index: 'esitoSched', name: 'esitoSched', sortable: false, width: 40},
			{index: 'statoUfficio', hidden: true, name: 'statoUfficio'},
			{index: 'statoUfficioIcon', name: 'statoUfficioIcon', width: 17}
		],
		gridComplete: function() {
			var rowData = $(this).getRowData();
			for (var cont = 0 ; cont < rowData.length ; cont++) {
				var dataDisattivazione = rowData[cont]['dataDisattivazione'];
				var dataDisattivazioneSplit = dataDisattivazione.split("/");
				var anno = dataDisattivazioneSplit[2];
				var mese = dataDisattivazioneSplit[1];
				var giorno = dataDisattivazioneSplit[0];
				dataDisattivazione = anno + mese + giorno;
				var now = new Date(); 
				giorno = ("0" + now.getDate()).slice(-2);
			    mese = ("0" + (now.getMonth() + 1)).slice(-2);
			    now = now.getFullYear() + mese + giorno;
			    if(now >= dataDisattivazione) {
					$(this).jqGrid('setCell', cont + 1, 'dataDisattivazione', '', {background: '#d7d7d7'});
				}
			    
			    if(rowData[cont]['statoUfficio'] == 'A') {
			    	$('#frazionariGrid').jqGrid('setCell', cont + 1, 'statoUfficioIcon', '<div title="Ufficio aperto" class="ui-icon ui-icon-unlocked"/>', {background: 'yellow'});
			    } else {
			    	$('#frazionariGrid').jqGrid('setCell', cont + 1, 'statoUfficioIcon', '<div title="Ufficio chiuso" class="ui-icon ui-icon-locked"/>');
			    }
			}
		},
		height: '437px',
		onSelectRow: function(id) {
			var rowData = $(this).getRowData(id); 
			var fraz = rowData['frazionario'];
			
			$('#pdlGrid').jqGrid('clearGridData');
			$.ajax({
				url: 'pdl.action?fraz=' + fraz,
				dataType: "json",
				success: function(response) {
					if(response['success']) {
						for(var cont = 0 ; cont < response['rows'].length ; cont++) {
							$('#pdlGrid').jqGrid('addRowData', cont + 1, {
								frazionario: response['rows'][cont]['frazionario'],
								nomePdl: response['rows'][cont]['nomePdl'],
								sezione: response['rows'][cont]['sezione'],
								versioneSDP: response['rows'][cont]['versioneSDP'],
								versioneClient: response['rows'][cont]['versioneClient'],
								dataDisattivazione: response['rows'][cont]['dataDisattivazione'],
								dataUltimaApertura: response['rows'][cont]['dataUltimaApertura'],
								dataAggiornamento: response['rows'][cont]['dataAggiornamento'],
								esito: response['rows'][cont]['esito']
							});
							
							var nomePdl = response['rows'][cont]['nomePdl'];
							var buttons = "<span class='ui-button ui-widget ui-state-default ui-corner-all ui-button-icon-only' onclick='apriLog(\"" + nomePdl + "\");' title='Visualizza Log'>" + 
								"<span class='ui-button-icon-primary ui-icon ui-icon-circle-zoomin'></span>" +
								"<span class='ui-button-text'>&nbsp;</span></span>" +
								"<span class='ui-button ui-widget ui-state-default ui-corner-all ui-button-icon-only' onclick='apriDirectoryLog(\"" + nomePdl + "\");' title='Apri directory Log'>" + 
								"<span class='ui-button-icon-primary ui-icon ui-icon-folder-open'></span>" +
								"<span class='ui-button-text'>&nbsp;</span></span>";
							$('#pdlGrid').jqGrid('setCell', cont + 1, 'buttons', buttons);
						}
						$('#pdlGrid').trigger("reloadGrid");
						$('#accordionFrazionari').accordion({active: 2});
					} else {
						$('<div><h3>Errore</h3><p>' + response['message'] + '</p></div>')
						.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
					}
				},
				error: function () {
					$('<div><h3>Errore</h3><p>Nessuna risposta dal server !</p></div>')
					.appendTo('#messageDiv').addClass('message').delay(1500).fadeOut();
				}
			});
		},
		pager: '#frazionariGridPager',
		rowNum: frazionariRowNum,
		sortname: 'frazionario',
		sortorder: 'asc',
		viewrecords: true
	}).jqGrid('navGrid', '#frazionariGridPager', {
		search: false,
		refresh: true,
		edit: false,
		add: false ,
		del: false
	}).jqGrid('navButtonAdd', '#frazionariGridPager', {
		caption: 'Esporta Frazionari',
		buttonicon: 'ui-icon-document',
		onClickButton: function() {
			var pianificati = $('#pianificati').val();
			var statoUffici = $('#statoUffici').val();
			var dataInizioMigrazione = $('#dataInizioMigrazione').val();
			var dataFineMigrazione = $('#dataFineMigrazione').val();
			var filtroEsitoOk = $('#filtroEsitoOk').is(':checked');
			var filtroEsitoKo = $('#filtroEsitoKo').is(':checked');
			var filtroEsitoKo2 = $('#filtroEsitoKo2').is(':checked');
			var filtroEsitoNA = $('#filtroEsitoNA').is(':checked');
			var filtroEsitoSched = $('#filtroEsitoSched').is(':checked');
			var filtroEsitoRollbackOk = $('#filtroEsitoRollbackOk').is(':checked');
			var filtroEsitoRollbackKo = $('#filtroEsitoRollbackKo').is(':checked');
			
			window.location = 'esportaFrazionari.action?pianificati=' + pianificati + '&statoUffici=' + statoUffici + '&dataInizioMigrazione=' + dataInizioMigrazione + '&dataFineMigrazione=' + dataFineMigrazione + '&filtroEsitoOk=' + filtroEsitoOk + "&filtroEsitoKo=" + filtroEsitoKo + "&filtroEsitoKo2=" + filtroEsitoKo2 + "&filtroEsitoNA=" + filtroEsitoNA + "&filtroEsitoSched=" + filtroEsitoSched + "&filtroEsitoRollbackOk=" + filtroEsitoRollbackOk +  "&filtroEsitoRollbackKo=" + filtroEsitoRollbackKo + '&aree=' + aree() + '&poli=' + poli() + '&provinceFiliali=' + provinceFiliali();
		},
		title:"Esporta Frazionari",
		cursor: "pointer"
	}).jqGrid('navButtonAdd', '#frazionariGridPager', {
		caption: 'Esporta Pdl',
		buttonicon: 'ui-icon-document',
		onClickButton: function() {
			var pianificati = $('#pianificati').val();
			var statoUffici = $('#statoUffici').val();
			var dataInizioMigrazione = $('#dataInizioMigrazione').val();
			var dataFineMigrazione = $('#dataFineMigrazione').val();
			var filtroEsitoOk = $('#filtroEsitoOk').is(':checked');
			var filtroEsitoKo = $('#filtroEsitoKo').is(':checked');
			var filtroEsitoKo2 = $('#filtroEsitoKo2').is(':checked');
			var filtroEsitoNA = $('#filtroEsitoNA').is(':checked');
			var filtroEsitoSched = $('#filtroEsitoSched').is(':checked');
			var filtroEsitoRollbackOk = $('#filtroEsitoRollbackOk').is(':checked');
			var filtroEsitoRollbackKo = $('#filtroEsitoRollbackKo').is(':checked');
			
			window.location = 'esportaPdl.action?pianificati=' + pianificati + '&statoUffici=' + statoUffici + '&dataInizioMigrazione=' + dataInizioMigrazione + '&dataFineMigrazione=' + dataFineMigrazione + '&filtroEsitoOk=' + filtroEsitoOk + "&filtroEsitoKo=" + filtroEsitoKo + "&filtroEsitoKo2=" + filtroEsitoKo2 + "&filtroEsitoNA=" + filtroEsitoNA + "&filtroEsitoSched=" + filtroEsitoSched + "&filtroEsitoRollbackOk=" + filtroEsitoRollbackOk +  "&filtroEsitoRollbackKo=" + filtroEsitoRollbackKo + '&aree=' + aree() + '&poli=' + poli() + '&provinceFiliali=' + provinceFiliali();
		},
		title:"Esporta Pdl",
		cursor: "pointer"
	});
	
	$('#migrazioneMassivaDialog').dialog({
		autoOpen: false,
		modal: true,
		resizable: false,
		title: 'Migrazione massiva',
		width: 195
	});
	
	$('#eseguiMigrazioneMassivaDialogButton').button({});
	$('#annullaMigrazioneMassivaDialogButton').button({});
	
	$('#pdlGrid').jqGrid({
		caption: 'Pdl',
		datatype: 'local',
		colNames: [
			'Fraz',
			'Nome Pdl',
			'Sezione',
			'Ver. SDP',
			'Ver. client',
			'Disattivazione',
			'Ultima apertura',
			'Aggiornamento',
			'Esito',
			''
		],
		colModel: [
			{align: 'center', index: 'frazionario', name: 'frazionario', width: 45},
			{align: 'center', index: 'nomePdl', name: 'nomePdl', width: 115},
			{align: 'center', index: 'sezione', name: 'sezione', width: 85},
			{align: 'center', index: 'versioneSDP', name: 'versioneSDP', width: 80},
			{align: 'center', index: 'versioneClient', name: 'versioneClient', width: 80},
			{align: 'center', index: 'dataDisattivazione', name: 'dataDisattivazione', width: 115},
			{align: 'center', index: 'dataUltimaApertura', name: 'dataUltimaApertura', width: 115},
			{align: 'center', index: 'dataAggiornamento', name: 'dataAggiornamento', width: 115},
			{index: 'esito', name: 'esito', width: 85},
			{index: 'buttons', name: 'buttons', width: 54}
		], 
		gridComplete: function() {
			var rowData = $(this).getRowData();
			var page = $(this).jqGrid('getGridParam', 'page'); 
			var rowNum = $(this).jqGrid('getGridParam', 'rowNum');
			var rowStart = rowNum * page - rowNum;
			for (var cont = 0 ; cont < rowData.length ; cont++) {
				var sezione = rowData[cont]['sezione'];
				if(sezione == '80' || sezione == '81') {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'sezione', '', {background: '#d7d7d7'});
				}
				
				if(rowData[cont]['versioneClient'] != rowData[cont]['versioneSDP']) {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'versioneClient', '', {background: '#d7d7d7'});
				}
				
				var dataDisattivazione = rowData[cont]['dataDisattivazione'];
				var dataDisattivazioneSplit = dataDisattivazione.split("/");
				var anno = dataDisattivazioneSplit[2];
				var mese = dataDisattivazioneSplit[1];
				var giorno = dataDisattivazioneSplit[0];
				dataDisattivazione = anno + mese + giorno;
				var now = new Date(); 
				giorno = ("0" + now.getDate()).slice(-2);
			    mese = ("0" + (now.getMonth() + 1)).slice(-2);
			    now = now.getFullYear() + mese + giorno;
			    if(now >= dataDisattivazione) {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'dataDisattivazione', '', {background: '#d7d7d7'});
				}	
				
				var esito = rowData[cont]['esito'];
				if(esito == '') {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'esito', '', {background: '#d7d7d7'});
				} else if(esito == 'OK') {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'esito', '', {background: '#00db00'});
				} else if(esito == 'KO') {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'esito', '', {background: '#da70d6'});
				} else if(esito == 'KO2') {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'esito', '', {background: '#ef2e0b'});
				} else if(esito == 'NA') {
					$(this).jqGrid('setCell', rowStart + cont + 1, 'esito', '', {background: '#ff9632'});
				}
			}
		},
		height: '476px',
		pager: '#pdlGridPager',
		rowNum: 20,
		sortname: 'nomePdl',
		sortorder: 'asc',
		viewrecords: true
	}).jqGrid('navGrid', '#pdlGridPager', {
		search:false,
		refresh:false,
		edit: false,
		add: false,
		del: false
	});
});