package it.poste.oracolo.servlet;


import it.poste.oracolo.business.Utente;
import it.poste.oracolo.common.logging.OracoloLogger;
import it.poste.oracolo.common.util.LoadPropertiesOracoloBatch;
import it.poste.oracolo.common.util.LoadPropertiesOracoloBatchBean;
import it.poste.oracolo.common.util.Utility;
import it.poste.oracolo.constants.OraEnum;
import it.poste.oracolo.dao.DBConnector;
import it.poste.oracolo.dao.common.UtilityDAO;
import it.poste.oracolo.exception.OracoloException;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Date;

import javax.faces.context.FacesContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.net.URI;
import java.net.URISyntaxException;
import org.owasp.encoder.Encode;

public class DownloadServlet extends HttpServlet {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	private static OracoloLogger oracoloLogger = OracoloLogger.getInstance();
	
	private Connection conn;

	public DownloadServlet(){
		
	}

	protected void doPost(HttpServletRequest request,HttpServletResponse response) throws ServletException, IOException {
		service(request, response);
	}

    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        String file = request.getParameter("fileName");
        String tipo = request.getParameter("tipo");

        HttpSession session = request.getSession();
        
        LoadPropertiesOracoloBatch loadProperties = new LoadPropertiesOracoloBatch();
		LoadPropertiesOracoloBatchBean propOraBatchBean = loadProperties.getPropBean();
		boolean FMG=false;
		String context = "";
		if (tipo.equalsIgnoreCase("kpi")){
			context = propOraBatchBean.getPathEXPORTsottoscrBatch();
			FMG=true;
			}
		else
			context = propOraBatchBean.getPathEXPORTdp();
		
		file=Encode.forJavaScript(file);
		file=file.replace("\\-", "-");
		
		
		String fileName = context+file;
		

		Integer  idEvento; 
		Integer  tipoOggetto;
		Integer  nomeFunzione;
		
		String 	 descOperazione = "Operazione di download file: "+file;

			idEvento       = OraEnum.VAL_TIPOEVENTO_DOWNLOAD_FILE_KPI_FMG_DP.getValue(); 
			tipoOggetto    = OraEnum.DESC_TIPOOGGETTO_DOWNLOAD_ESTRAZIONI_E_DP.getValue();
			nomeFunzione   = OraEnum.NOME_FUNZIONE_EXPORT_FMG_DP.getValue(); 
		

		if(fileName.contains("..") || fileName.contains("%2E%2E%2F") || fileName.contains("%252E%252E%252F"))
			oracoloLogger.info("file ["+fileName+"] NON valido");
		
		else{ 
			
			//String fileName = file;
			//String fileName = "";
			String fileType = ".CSV";
			// Find this file id in database to get file name, and file type

			oracoloLogger.info("cerco il file "+fileName);
        		 
			File myFile = new File(fileName);
         
			if (myFile.exists()) {
        	 
				oracoloLogger.info("file ["+fileName+"] trovato");
             
        	 
				// You must tell the browser the file type you are going to send
				// for example application/pdf, text/plain, text/html, image/jpg
				response.setContentType(fileType);

	            // Make sure to show the download dialog
	            response.setHeader("Content-disposition","attachment; filename="+file);
	
	            // Assume file name is retrieved from database
	            
	
	            // This should send the file to browser
	        	OutputStream out = response.getOutputStream();
	        	FileInputStream in = new FileInputStream(myFile);
	        	byte[] buffer = new byte[4096];
	        	int length;
	        	while ((length = in.read(buffer)) > 0){
	        		 out.write(buffer, 0, length);
	        	}
	        	in.close();
	        	out.flush();
	        	 
	        	oracoloLogger.info("fine scaricamento");
	        	
	        	Utente utente = (Utente)session.getAttribute("utente");
				String idUtente = utente.getIdUtente();
	        	try {
					traceOperazioneUtente(idEvento, tipoOggetto, nomeFunzione, idUtente, descOperazione);
				} catch (SQLException e) {
					oracoloLogger.error("SQLException in traceOperazioneUtente() method - DownloadServlet.java",e);
					throw new OracoloException("db_error");
				}
				
	         }
	         else{
	        	 oracoloLogger.info("file ["+fileName+"] NON trovato");
	         }
		}
    }
    
    
    public void traceOperazioneUtente(Integer idEvento, Integer tipoOggetto, Integer nomeFunzione, String operatore, String descOperazione) throws SQLException {
		conn = DBConnector.getConnection();
		conn.setAutoCommit(false);
		try {
			traceHelperOperazioneUtente(conn, idEvento, tipoOggetto, nomeFunzione, operatore, descOperazione);
			conn.commit();
		} catch(SQLException e){
			conn.rollback(); 
		} catch(Exception e){
			conn.rollback();
		} finally{
			if (conn != null) {
				
				conn.close();
			}
		}
	}
    
    public void traceHelperOperazioneUtente(Connection conn, Integer idEvento, Integer tipoOggetto, Integer nomeFunzione, String operatore, String descOperazione) throws SQLException {

		PreparedStatement ps = null;
		
		try{
		long idOperazioneUtente = getMaxKey(conn);
		String query = " INSERT INTO OPERAZIONEUTENTE "
				+ " (ID_OPERAZIONEUTENTE,FK_TIPOEVENTO,FK_TIPOOGGETTO,FK_FUNZIONE,FK_UTENTE,DATA_OPERAZIONEUTENTE,DESC_OPERAZIONEUTENTE) "
				+ " VALUES(?,?,?,?,?,?,?) ";

		ps = conn.prepareStatement(query);
		ps.setLong(1, idOperazioneUtente);
		ps.setInt(2, idEvento);
		ps.setInt(3, tipoOggetto);
		ps.setInt(4, nomeFunzione);
		ps.setString(5, operatore);
		ps.setString(6, new Timestamp(new Date().getTime()).toString());
		ps.setString(7, descOperazione);
		ps.executeUpdate();
		ps.close();
		
		} catch (Exception e) {
			oracoloLogger.error("Errore insert operazione utente - DownloadServlet.traceHelperOperazioneUtente",e);
			throw new SQLException(e.getMessage());
		} finally{
			UtilityDAO.chiudiAll(null, ps, null);
		}

	}
    
    private Long getMaxKey (Connection conn){
		PreparedStatement ps = null;
		ResultSet rs = null;
		Long maxKey = Long.valueOf(0);
		try {
			String query = "VALUES NEXTVAL FOR SEQ_OPERAZIONEUTENTE";
			ps = conn.prepareStatement(query);
			
			rs = ps.executeQuery();
			if ( rs.next() )
				return rs.getLong(1);

			oracoloLogger.info("Max indice letto con successo.");

		} catch (Exception e) {
			oracoloLogger.error("Errore nella lettura del max indice.",e);
		} finally{
			UtilityDAO.chiudiAll(rs, ps, null);
			
		}
		return maxKey;

	}
    
    
}