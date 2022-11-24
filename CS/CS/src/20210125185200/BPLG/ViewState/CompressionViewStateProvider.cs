using System;
using System.IO;
using System.Web;
using System.Web.UI;
using System.Web.Util;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Collections.Specialized;


namespace BPLG.ViewState
{
	/// <summary>
	/// ViewState Provider that compress the view state string
	/// 
	/// Scott Galloway has a blog entry where he discusses his experiences 
	/// with using #ziplib library to compress the view state. For more info,
	/// please visit http://www.mostlylucid.co.uk/
	/// </summary>
	public class CompressionViewStateProvider : ViewStateProviderBase 
	{
		#region Member Vars
		private string _name;
		private LosFormatter los;
		private StringWriter writer;
		#endregion
		
		#region ctor
		public CompressionViewStateProvider (string connectionString) 
		{
			los = new LosFormatter();
			writer = new StringWriter();
		}
		#endregion

		#region ViewStateProvider specific behaviors
		public override object LoadPageState(System.Web.UI.Control pControl)
		{	
			string vsString = ((Page)pControl).Request.Form["__COMPRESSEDVIEWSTATE"];
			string outStr = Compression.DeCompress(vsString);
			return los.Deserialize(outStr);
		}
				
		public override void SavePageState(System.Web.UI.Control pControl, object viewState)
		{	
			los.Serialize(writer, viewState);
			string outStr = Compression.Compress(writer.ToString());
			((Page)pControl).RegisterHiddenField("__COMPRESSEDVIEWSTATE", outStr);
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