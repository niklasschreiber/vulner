package it.poste.oracolo.batch.socket;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.concurrent.TimeUnit;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.Logger;

import it.poste.oracolo.batch.business.sbloccoblocco.TimeoutController;
import it.poste.oracolo.batch.business.sbloccoblocco.TimeoutController.TimeoutException;
import it.poste.oracolo.batch.common.Utility;
import it.poste.oracolo.batch.dao.backlog.BacklogDAO;
import it.poste.oracolo.batch.dao.common.DBConnector;
import it.poste.oracolo.batch.esportazioneDati.business.ExportDatiBatchBusiness;
import it.poste.oracolo.batch.exception.DumpFileException;
import it.poste.oracolo.batch.exception.ReadFileException;
import it.poste.oracolo.batch.exception.WriteFileException;
import it.poste.oracolo.batch.handleErrorCodeMessage.HandleErrorCodeMessage;
import it.poste.oracolo.batch.log.LoggerBatchExportAlertChiusi;
import it.poste.oracolo.batch.utility.DetailInfoBatch;
import it.poste.oracolo.batch.utility.LoadPropertiesOracoloBatch;
import it.poste.oracolo.batch.utility.LoadPropertiesOracoloBatchBean;
import it.poste.oracolo.batch.utility.UtilityClass;

public class ServletExportAlertChiusi extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = LoggerBatchExportAlertChiusi.getInstance();
	LoadPropertiesOracoloBatchBean propOraBatchBean = null;
	private static SimpleDateFormat sdfDetail = new SimpleDateFormat("ddMMyyyy-HH.mm.ss");
	HandleErrorCodeMessage hecm;
	Long timeInitial;
	
	public ServletExportAlertChiusi() {
		super();
	}

	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		final PrintWriter out = response.getWriter();
		final DetailInfoBatch detailInfoBatch = new DetailInfoBatch();
		String orarioStop = "";
		hecm = new HandleErrorCodeMessage();
		
		logger.info("Inizio EXPORT ALERT CHIUSI KPI");

		detailInfoBatch.setTipoProdotto("EXPORT ALERT CHIUSI KPI");
		timeInitial = System.currentTimeMillis();
		detailInfoBatch.setDataInizioCaricamento(sdfDetail.format(timeInitial));
		
		try{
			logger.info("Inizio controllo entries da file di properties ...");
			LoadPropertiesOracoloBatch loadProperties = new LoadPropertiesOracoloBatch();
			propOraBatchBean = loadProperties.getPropBean();
			if (propOraBatchBean.getPathFMG_AXWAY() == null || propOraBatchBean.getPathFMG_AXWAY().isEmpty())
				throw new Exception("Exception in doGet() method - ServletExportAlertChiusi.java - PathFMG_AXWAY non inizializzato nel file di properties");
			if (propOraBatchBean.getTimeExportFMG() == null || propOraBatchBean.getTimeExportFMG().isEmpty())
				throw new Exception("Exception in doGet() method - ServletExportAlertChiusi.java - timeStopExportFMG non inizializzato nel file di properties");
			orarioStop = propOraBatchBean.getTimeExportFMG();
			logger.info("Fine controllo entries da file di properties");
		
			Runnable task = new Runnable(){
				Connection conn = null;
				BacklogDAO backlogDAO = null;
				public void run() {
					try {

						logger.info("Inizio apertura connessione con DB ...");
						conn = DBConnector.getConnection();
						logger.info("Connessione con DB completata.");
						
						service(conn);

						detailInfoBatch.setEsito(0);
						Long timeFinal = System.currentTimeMillis();
						detailInfoBatch.setDataFineCaricamento(sdfDetail.format(timeFinal));
						detailInfoBatch.setDurata(TimeUnit.MILLISECONDS.toMinutes(timeFinal - timeInitial));

						backlogDAO = (BacklogDAO) Utility.getDAOFactory().getDAOImpl(BacklogDAO.class);
						if(backlogDAO.insertInfoBatchCommon(logger,conn,detailInfoBatch,out,timeInitial)){
							out.println("0");
							logger.info("Processo terminato con codice di ritorno: 0 - Programma completato con successo");
						}
						logger.info("Fine EXPORT ALERT CHIUSI KPI: tempo totale " + (timeFinal - timeInitial) + " ms");	

					} catch (Exception e) {
						HandleErrorCodeMessage.handleErrorCodeMessage(logger,e,out,conn,detailInfoBatch,timeInitial);
					}
				}
			};
				
			try {
				TimeoutController.execute(task, UtilityClass.tempoSchedulazioneTimeController(logger,orarioStop));
			} catch (TimeoutException e) {
				logger.error("InterruptedException in doGet method(): "+e.getMessage(),e);
			}  catch (Exception e) {
				logger.error("Exception in doGet method(): "+e.getMessage(),e);
			}
		}catch(Exception e){
			HandleErrorCodeMessage.handleErrorCodeMessage(logger,e,out,null,detailInfoBatch,timeInitial);
		}	
	}

	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		doGet(request, response);
	}

	public void service(Connection conn) throws Exception {

		ExportDatiBatchBusiness exportDatiBusiness = new ExportDatiBatchBusiness();

		String lastDate = null;
		try{
			lastDate = exportDatiBusiness.getLastAlertDateExported(conn,logger);
		} catch (SQLException e) {
			throw new SQLException(e.getMessage());
		} catch (Exception e) {
			throw new Exception(e.getMessage());
		}
		
		try{
			if (lastDate != null) 
				exportDatiBusiness.exportAlertFromDateAgg(lastDate,conn,logger);
		} catch (SQLException e){
			throw new SQLException(e.getMessage());
		} catch (WriteFileException e){
			throw new WriteFileException(e.getMessage());
		} catch (ReadFileException e){
			throw new ReadFileException(e.getMessage());
		} catch (FileNotFoundException e){
			throw new FileNotFoundException(e.getMessage());
		} catch (DumpFileException e){
			throw new DumpFileException(e.getMessage());
		} catch (Exception e){
			throw new Exception(e.getMessage());
		}
		
	}
	
}
