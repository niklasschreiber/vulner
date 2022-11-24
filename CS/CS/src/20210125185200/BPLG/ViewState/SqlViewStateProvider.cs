using System;
using System.IO;
using System.Web;
using System.Web.UI;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Specialized;


namespace BPLG.ViewState
{
	/// <summary>
	/// ViewState Provider that store view state in SQL Server database.
	/// </summary>
	public class SqlViewStateProvider : ViewStateProviderBase 
	{
		#region Member Vars
		private string _name;
		private string _connectionString;
        private int _idWebApplication;
        #endregion
		
		#region Ctor
        public SqlViewStateProvider(string connectionString, int idWebApplication) 
		{
			_connectionString = connectionString;
            _idWebApplication = idWebApplication;
		}
		#endregion

		#region ViewStateProvider specific behaviors
		public override object LoadPageState(System.Web.UI.Control pControl)
		{	
			string vsKey = ((Page)pControl).Request.Form["__vsKey"];
			
			using(SqlConnection conn = new SqlConnection(_connectionString))
			{
				conn.Open();
				
				try
				{
					using(SqlCommand cmd = new SqlCommand("SqlViewStateProvider_GetViewState", conn))
					{
						cmd.CommandType = CommandType.StoredProcedure;

                        //	Id Web Application
                        cmd.Parameters.Add("@nIdWebApplication", SqlDbType.Int);
                        cmd.Parameters["@nIdWebApplication"].Value = _idWebApplication;
                        //	Key
						cmd.Parameters.Add("@vsKey", SqlDbType.NVarChar, 100);
						cmd.Parameters["@vsKey"].Value = vsKey;
						
						object vs = cmd.ExecuteScalar();
						//	Deserialize the view state string into object
						LosFormatter los = new LosFormatter();
						return los.Deserialize(vs.ToString());
					}
				}
				catch(Exception ex)
				{
					System.Diagnostics.Trace.WriteLine(ex.Message);
					throw ex;
				}
			}
		}
				
		public override void SavePageState(System.Web.UI.Control pControl, object viewState)
		{	
			string vsKey = String.Empty;
			
			//	Searching for the hidden field named "__vsKey"
			System.Web.UI.HtmlControls.HtmlInputHidden ctrl = (System.Web.UI.HtmlControls.HtmlInputHidden)pControl.FindControl("__vsKey");
			if (ctrl == null)
			{
				//	Generate new GUID
				vsKey = Guid.NewGuid().ToString();
				//	Store in the hidden field
				((Page)pControl).RegisterHiddenField("__vsKey", vsKey);
			}
			else
			{
				//	Use the GUID stored in the hidden field
				vsKey = ctrl.Value;
			}
			
			//StringWriter writer = new StringWriter();
            //TextWriter writer = new TextWriter();
            MemoryStream writer = new MemoryStream();

			try
			{
				//	Serialize the ViewState into String
				LosFormatter los = new LosFormatter();
				los.Serialize(writer, viewState);
							
				//	Store the view state into database
				using(SqlConnection conn = new SqlConnection(_connectionString))
				{
					conn.Open();
				
					using(SqlCommand cmd = new SqlCommand("SqlViewStateProvider_SaveViewState", conn))
					{
						cmd.CommandType = CommandType.StoredProcedure;

                        //	Id Web Application
                        cmd.Parameters.Add("@nIdWebApplication", SqlDbType.Int);
                        cmd.Parameters["@nIdWebApplication"].Value = _idWebApplication;

                        //	Key
						cmd.Parameters.Add("@vsKey", SqlDbType.NVarChar, 100);
						cmd.Parameters["@vsKey"].Value = vsKey;
				
						//	Serialized ViewState
						cmd.Parameters.Add("@vsValue", SqlDbType.NText, writer.ToString().Length);
						cmd.Parameters["@vsValue"].Value = writer.ToString();
				
						cmd.ExecuteNonQuery(); 
					}
				}
			}
			catch( Exception ex) 
			{
				System.Diagnostics.Trace.WriteLine(ex.Message);
			}
			finally
			{
				writer.Close();
			}
		}
		#endregion
	
		#region Provider specific behaviors
		public override void Initialize(string name, NameValueCollection configValue) 
		{
			this._name = name;
		}

		public override string Name 
		{
			get { return _name; }
		}
		#endregion
	}
}