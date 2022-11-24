using System;
using System.Xml;
using System.Configuration;


namespace BPLG.ViewState 
{
	/// <summary>
	/// ViewState Provider Configuration Handler
	/// </summary>
	public class ViewStateConfigurationHandler : IConfigurationSectionHandler 
	{
		public virtual object Create(Object parent, Object context, XmlNode node) 
		{
			ViewStateConfiguration config = new ViewStateConfiguration();
			config.LoadValuesFromConfigurationXml(node);
			return config;
		}
	}

}