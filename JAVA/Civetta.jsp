<%@ include file="/WEB-INF/pages/common/taglibs.jsp"%>
<!-- Avoid using SQL API in JSP (SRA) -->
<%@ page import = "java.sql.*" %>
<%@ page import = "javax.sql.*" %>


<tiles:insertDefinition name="basicTemplate" >

	<tiles:putAttribute name="body">
	 
	  <table style="width: 100%" id="id_tab" >
	    <tr> <td width="10%" align="right" ><div style="margin:0" id="panel_min" /></td>
	         <td width="80%" align="middle"><div  style="margin:0;width:100%" id="panel_master" /></td>
	        <td width="10%" align="left"><div style="margin:0" id="panel_min_right" /></td>
	    </tr>
	  </table> 
	  
	   
	   <s:hidden id="count"  name="countn" value="%{searchForm.size}"/>
	   
	   <s:iterator value="%{searchForm}" var="item" status="idx">
	    <!--   <s:hidden id="item%{#idx.index}"  name="item%{#idx.index}" value="getItem%{searchForm[#idx.index].dataSetSource}()"/>-->
	    <s:hidden id="item%{#idx.index}"  name="searchForm[#idx.index].dataSetSource" value="getItem%{searchForm[#idx.index].dataSetSource}"/>
	   </s:iterator>
	 
          <table>
	      <tr>
	         <td width='20%'>
             <tiles:insertDefinition name="box">
           <tiles:putAttribute name="title" value="label.statisticOverview.load" />
           <tiles:putAttribute name="body-id" value="Statistic-Overview" />
           <tiles:putAttribute name="header_other_info" cascade="false">
             <div id="summarystat" style="float:right;" >
             </div>

            </tiles:putAttribute>

          <tiles:putAttribute name="body">
                  <div id="trust_kpi_statistic">
                </div>
          </tiles:putAttribute>
          </tiles:insertDefinition>


            </td>
	             

	      </tr>

    	 </table>

<script type="text/javascript" src="../chart/chartUtils.js"></script>
<jsp:include page="../chart/chart-Swift.jsp" />
<jsp:include page="../chart/chart-Eba.jsp" />
<jsp:include page="../chart/chart-Icbpi.jsp" />
<jsp:include page="../chart/chart-Sia.jsp" />
<jsp:include page="../chart/chart-Tgt.jsp" />
<jsp:include page="../chart/empty_panel.jsp" />

<script type="text/javascript">

					Ext.onReady(function(){

			     
			        Ext.define('HomeKpiItemMasterdata', {
					    extend: 'Ext.data.Model',
					    fields: ['dataSet','dataSetCode','dataSetSource','initElabDate','endElabDate', 'elabResult','elabReco','loadMode','errorDesc','flagLoad']
					});



			        var i = 0;
			       
					   //console.log('count:' + '%o' , $("#item"+i).val());
                    var anagItem = [];
                    anagItem_r = [];
                    var anagItem_c = [];
                    var anag;
                    var count_l = 0;
                    var count_r = 0;
                    
                   /* anagItem.push(window["getItemICBPI"](false));
                    anagItem.push(window["getItemEBA"](false));
                    anagItem_c.push(window["getItemEBA"](true));*/
                   
                  for(i=0; i<$("#count").val(); i++){
                            anag=$("#item"+i).val();
                            // console.log('item:' + '%o' , anag.toString());
                            if (anag=="getItemICBPI"){
                                if(anagItem.length==3)
                 	             anagItem_r.push(window["getItemICBPI"](false));
                                else 
                             	 anagItem.push(window["getItemICBPI"](false));
                                if(anagItem_c.length==0){
                                    anagItem_c.push(window["getItemICBPI"](true));
                                }
                            }
                            if (anag=="getItemEBA"){
                              
                               if(anagItem.length==3)
                  	             anagItem_r.push(window["getItemEBA"](false));
                         	   else 
                         		 anagItem.push(window["getItemEBA"](false)); 
                               if(anagItem_c.length==0){  anagItem_c.push(window["getItemEBA"](true));}
                            }
                            if (anag=="getItemSIA"){
                               
                               if(anagItem.length==3)
                   	             anagItem_r.push(window["getItemSIA"](false));
                         	   else 
                         		  anagItem.push(window["getItemSIA"](false));
                            if(anagItem_c.length==0){
                                anagItem_c.push(window["getItemSIA"](true));}
                            }
                            if (anag=="getItemSWIFT"){
                                
                                if(anagItem.length==3)
                   	             anagItem_r.push(window["getItemSWIFT"](false));
                         	   else 
                         		  anagItem.push(window["getItemSWIFT"](false));
                                if(anagItem_c.length==0)
                                    anagItem_c.push(window["getItemSWIFT"](true));
                            }
                            if (anag=="getItemTGT"){
                              
                               if(anagItem.length==3)
                   	             anagItem_r.push(window["getItemTGT"](false));
                         	   else
                         		 anagItem.push(window["getItemTGT"](false));
                            if(anagItem_c.length==0){
                                anagItem_c.push(window["getItemTGT"](true));}
                            }
                        }
                        
count_l = anagItem.length;
count_r = (anagItem_r.length);
//console.log(count_l + " " + anagItem_c.length);
  for(count_l;count_l<3;count_l++){
	  anagItem.push(window["getItemEmpty"]('id_emptyl'+count_l));
	  }
  for(count_r;count_r<3;count_r++){
	  anagItem_r.push(window["getItemEmpty"]('id_emptyr'+count_r));
	  
	  }
/*if(count_l<3){
	  anagItem.push(window["getItemEmpty"](false));
}
	  if(count_r<3){
		  anagItem_r.push(window["getItemEmpty"](false));
	 }*/

 
			        //pannello principale grafico
			      
			       //Ext.fly('panel_min').update('');
			      // Ext.fly('panel_min_right').update('');
			       /*Ext
					.create(
							'Ext.panel.Panel',
							{
								id : 'chart-master-panel',
								items : anagItem_c,
								flex: 1,
								height : 290,
								//width : 964,
								renderTo : 'panel_master',
								bodyStyle : 'background-color: #FFF !important; border: 0px',
								layout : {
									type : 'hbox',
									align : 'stretch'
								}
								
							});*/
				
                      //pannello secondario- miniature grafici autoWidth : true,
                       Ext.fly('panel_min').update('');
      					Ext
						.create(
								'Ext.panel.Panel',
								{
									id : 'chart-min-panel',
									width : 150,
									height : 290,
									layout: 'fit',
									renderTo : 'panel_min',
									bodyStyle : 'background-color: #FFF !important; border: 0px',
									layout : {
										type : 'vbox',
										align : 'stretch'
									},
									items : anagItem
								});
      					
      					//anagItem_r.push(window["getItemEmpty"](false));
      					 //pannello secondario- miniature grafici autoWidth : true,
      					 Ext.fly('panel_min_right').update('');
      					Ext
						.create(
								'Ext.panel.Panel',
								{
									id : 'chart-min-panel_right',
									width : 150,
									height : 290,
									layout: 'fit',
									renderTo : 'panel_min_right',
									bodyStyle : 'background-color: #FFF !important; border: 0px',
									layout : {
										type : 'vbox',
										align : 'stretch'
									},
									items : anagItem_r
								});

						//pannello principale
      					Ext.fly('panel_master').update('');
      	            	Ext
      					.create(
      							'Ext.panel.Panel',
      							{
      								id : 'chart-main-panel',
      								autoWidth : true,
      								//autoHeight : true,
      								height : 290,
      								//width:600,
      								renderTo : 'panel_master',
      								bodyStyle : 'background-color: #FFF !important; border: 0px',
      								layout : {
      									type : 'hbox',
      									align : 'stretch'
      								},
      								items : anagItem_c
      							});
      					

      					      Ext.define('HomeKpiItemMasterdata', {
											    extend: 'Ext.data.Model',
											    fields: ['dataSet','dataSetCode','dataSetSource','initElabDate','endElabDate', 'elabResult','elabReco','loadMode','errorDesc','flagLoad','dataFileName']
											});
									 

					   				         //new grid statistic
								          var homeKpiStoreStatistic=  Ext.create('Ext.data.Store', {
												storeId: 'homeKpiStoreStatistic',
											     model: 'HomeKpiItemMasterdata',
											     proxy: {
											         type: 'ajax',
											         url: '<s:url action="masterdata-summary"/>',
											         reader: {
											             type:'json',
											             root:'data'
											         }
											     },
 
											     autoLoad:true
											 });


											  Ext.create('Ext.grid.Panel', {
												id: 'homeKpiGrid-id',
										      	store: homeKpiStoreStatistic,
										      	renderTo: 'trust_kpi_statistic',
										      	 height: 170,
										      	viewConfig: {
										        	stripeRows: true,
										          	trackOver: true
										      	},
										      	columns: [
													      	{
													        	text: '<s:text name="label.dataset" />',
													            width    : 110,
													          	flex    : 1,
													          	sortable : false,
													          	align	: 'left',
													          	dataIndex: 'dataSet'
													      	}, {
													          text: '<s:text name="label.datasetsource" />',
													          width    : 80,
													          sortable : false,
													          align	: 'center',
													          dataIndex: 'dataSetSource'

															},
															{
																text: '<s:text name="label.datafilename" />',
														          width    : 160,
														          sortable : false,
														          align	: 'left',
														          dataIndex: 'dataFileName'

															},
															{
																 text: '<s:text name="label.elabdate.init" />',
														          width    : 160,
														          sortable : false,
														          align	: 'center',
														          dataIndex: 'initElabDate',
														         

															},
															{
																 text: '<s:text name="label.elabdate.end" />',
														          width    : 160,
														          sortable : false,
														          align	: 'center',
														          dataIndex: 'endElabDate'

															},
															{
																 text: '<s:text name="label.elabresult" />',
														          width    : 60,
														          sortable : false,
														          align	: 'center',
														          dataIndex: 'elabResult',

														           renderer: function(value, metaData, record, rowIndex, colIndex, store) {


														           		if (value!=null && value.length != 0) {
														           		  return	setPngStatus(value,record);
															           }


															            return value;
															        }


															},
															{
																text: '<s:text name="label.elabreco" />',
														          width    : 80,
														          sortable : false,
														          align	: 'right',
														          dataIndex: 'elabReco'

															},
															{
																text: '<s:text name="label.loadmode" />',
														          width    : 60,
														          sortable : false,
														          align	: 'center',
														          dataIndex: 'loadMode'

															},
															{
																text: '<s:text name="label.errordesc" />',
														          width    : 120,
														          sortable : false,
														          align	: 'left',
														          dataIndex: 'errorDesc'

															}

													      	]

														});
					   				         
					   				         
					   				         

						



					});

					function getPngImage(node, id){
						var url = new Array();

					

						url[0]='<img id="'+id+'" src="../core/img/icons/fugue/tick-circle.png"/>';
						url[1]='<img id="'+id+'" src="../core/img/icons/fugue/minus-circle-gray.png"/>';
						url[2]='<img id="'+id+'" src="../core/img/icons/fugue/cross-circle.png"/>';
						url[3]='<img id="'+id+'" src="../core/img/icons/fugue/exclamation-white.png"/>';
						url[4]='<img id="'+id+'" src="../core/img/icons/fugue/exclamation.png"/>';

						
						var status_D=0;
		        		var status_OK=0;
		        		var status_KO=0;
		        		var status_OH=0;
		        		var status_XX=0;

		        		for (var i=0; i<node.length;i++){
			        		if(node[i].data.flagLoad=='D' )  status_D++;
			        	    if(node[i].data.elabResult=='OK' ) status_OK++;
			        	    if(node[i].data.elabResult=='KO' ) status_KO++;
			        	    if(node[i].data.elabResult=='OH' ) status_OH++;
			        	    if(node[i].data.elabResult=='XX' ) status_XX++;
		        		}

		        	 
						 
						if (status_XX==node.length) return url[3];
						if (status_KO>0) return url[2];
						if (status_OH>0) return url[4];
						if (status_OK==node.length) return url[0];
			
					 

					}

					function setPngStatus(statusValue,record){
						var url = new Array();
						url[0]="../core/img/icons/fugue/tick-circle.png";
						url[1]= "../core/img/icons/fugue/cross-circle.png";
						url[2]= "../core/img/icons/fugue/minus-circle.png";
						url[3]= "../core/img/icons/fugue/exclamation-white.png";
					
						url[4]= "/vtpieconsole/core/img/icons/fugue/exclamation.png";

					
						
						  if (statusValue=='OK') {



		           				return '<div style="width:100%;height:16px;background-image:url('+url[0]+');background-position:center center;background-repeat:no-repeat;">&nbsp;</div>';

		           			}
		           			else if (statusValue=='KO'){
		           				return '<div style="width:100%;height:16px;background-image:url('+url[1]+');background-position:center center;background-repeat:no-repeat;">&nbsp;</div>';


		           			}
		           			else if (statusValue=='OH'){
		           				return '<div style="width:100%;height:16px;background-image:url('+url[4]+');background-position:center center;background-repeat:no-repeat;">&nbsp;</div>';


		           			}
		           			else if (statusValue=='XX'){
		           				return '<div style="width:100%;height:16px;background-image:url('+url[3]+');background-position:center center;background-repeat:no-repeat;">&nbsp;</div>';


		           			}

						}

 

				</script>

    </tiles:putAttribute>

</tiles:insertDefinition>


