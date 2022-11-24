using System;
using System.Reflection;
using System.Web.Caching;
using System.Collections.Specialized;
using System.Web;


namespace BPLG.ViewState 
{
	public abstract class ViewStateProviderBase : ProviderBase 
	{
		#region Functions to be implemented by specific ViewStateProvider
		
		/// <summary>
		/// Loads any saved view-state of the current page from virtually any 
		/// storage medium other than a hidden field 
		/// </summary>
		/// <param name="pControl">System.Web.UI.Page</param>
		/// <returns>The saved view state</returns>
		public abstract System.Object LoadPageState(System.Web.UI.Control pControl);

		/// <summary>
		/// Saves any view-state information of the page to virtually any 
		/// storage medium other than a hidden field
		/// </summary>
		/// <param name="pControl">System.Web.UI.Page</param>
		/// <param name="viewState">An System.Object in which to store the view-state information</param>
		public abstract void SavePageState(System.Web.UI.Control pControl, System.Object viewState);

		#endregion
		
		#region Instance
		public static ViewStateProviderBase Instance() 
		{
			// Use the cache because the reflection used later is expensive
			Cache cache = HttpRuntime.Cache;
			Type type = null;
			string cacheKey = null;

			// Get the names of the providers
			ViewStateConfiguration config = ViewStateConfiguration.GetConfig();

			// Read the configuration specific information
			// for this provider
			Provider vsProvider = (Provider) config.Providers[config.DefaultProvider];

			// In the cache?
			cacheKey = "vsProvider::" + config.DefaultProvider;
			if ( cache[cacheKey] == null ) 
			{
				// The assembly should be in \bin or GAC, so we simply need
				// to get an instance of the type
				try 
				{	
					type = Type.GetType( vsProvider.Type );
					if (type == null)
					{	
						// Assembly not in GAC then lookup the \bin directory
						string[] types = vsProvider.Type.Split(',');
						//	types[0] - Type Name
						//	types[1] - Assembly Name
						
						Assembly asm = Assembly.Load(types[1]);
						type = asm.GetType( types[0] );
					}
					
					// Insert the type into the cache
					Type[] paramTypes = new Type[2];
					paramTypes[0] = typeof(string);
                    paramTypes[1] = typeof(int);
                    cache.Insert(cacheKey, type.GetConstructor(paramTypes));
				} 
				catch (Exception e) 
				{
					throw new Exception("Unable to load the Provider", e);
				}
			}
			
			// Load the configuration settings
			object[] paramArray = new object[2];
			paramArray[0] = vsProvider.Attributes["connectionString"];
            paramArray[1] = Convert.ToInt32(vsProvider.Attributes["idWebApplication"]);
			
			return (ViewStateProviderBase)(  ((ConstructorInfo)cache[cacheKey]).Invoke(paramArray) );
		}
		#endregion
	}
}