using System;


namespace BPLG.ViewState
{

	public class ViewStateManager
	{
		public static System.Object LoadPageState(System.Web.UI.Control pControl) 
		{
			ViewStateProviderBase provider = ViewStateProviderBase.Instance();
			
			return provider.LoadPageState(pControl);
		}

		public static void SavePageState(System.Web.UI.Control pControl, System.Object viewState)
		{
			ViewStateProviderBase provider = ViewStateProviderBase.Instance();
			
			provider.SavePageState(pControl, viewState); 
		}
	}
}
