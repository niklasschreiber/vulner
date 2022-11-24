using System;
using System.Collections.Specialized;


namespace BPLG.ViewState 
{
	/// <summary>
	/// Base class for all the Providers
	/// </summary>
	public abstract class ProviderBase 
	{
		public abstract void Initialize (string name, NameValueCollection configValue);
		public abstract string Name { get; }
	}
}