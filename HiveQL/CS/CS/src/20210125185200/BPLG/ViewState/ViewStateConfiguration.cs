using System;
using System.Xml;
using System.Collections;
using System.Collections.Specialized;
using System.Configuration;


namespace BPLG.ViewState 
{
	public class ViewStateConfiguration 
	{
		#region Member Vars
		private string defaultProvider;
		private Hashtable providers = new Hashtable();
		#endregion
		
		#region Properties
		
		public string DefaultProvider 
		{ 
			get { return defaultProvider; } 
		}
		
		public Hashtable Providers 
		{ 
			get { return providers; } 
		} 
		
		#endregion
		
		#region GetConfig
		public static ViewStateConfiguration GetConfig() 
		{
			return (ViewStateConfiguration) ConfigurationSettings.GetConfig("system.web/viewstate");
		} 
		#endregion
		
		#region LoadValuesFromConfigurationXml
		public void LoadValuesFromConfigurationXml(XmlNode node) 
		{
			XmlAttributeCollection attributeCollection = node.Attributes;
			
			// Read child nodes
			foreach (XmlNode child in node.ChildNodes) 
			{
				if (child.Name == "providers")
					GetProviders(child);
			}
									
			// Get the default provider
			defaultProvider = attributeCollection["defaultProvider"].Value;
			if (!providers.ContainsKey(defaultProvider))
				throw new ConfigurationException(String.Format("Unable to locate the [{0}] ViewStateProvider!", defaultProvider), node); 
		}
		#endregion
		
		#region GetProviders
		void GetProviders(XmlNode node) 
		{
			foreach (XmlNode provider in node.ChildNodes) 
			{
				switch (provider.Name) {
					case "add" :
						providers.Add(provider.Attributes["name"].Value, new Provider(provider.Attributes) );
						break;

					case "remove" :
						providers.Remove(provider.Attributes["name"].Value);
						break;

					case "clear" :
						providers.Clear();
						break;
				}
			}
		}
		#endregion
	}

	public class Provider 
	{
		#region Member Vars
		private string name;
		private string providerType;
		private NameValueCollection providerAttributes = new NameValueCollection();
		#endregion
		
		#region Properties

		public string Name 
		{
			get { return name; }
		}
		
		public string Type 
		{
			get { return providerType; }
		}
		
		public NameValueCollection Attributes 
		{
			get { return providerAttributes; }
		}
		
		#endregion
		
		#region ctor
		public Provider (XmlAttributeCollection attributes) 
		{
			// Set the name of the provider
			//
			name = attributes["name"].Value;

			// Set the type of the provider
			//
			providerType = attributes["type"].Value;

			// Store all the attributes in the attributes bucket
			foreach (XmlAttribute attribute in attributes) 
			{
				if ( (attribute.Name != "name") && (attribute.Name != "type") )
					providerAttributes.Add(attribute.Name, attribute.Value);
			}
		}
		#endregion
	}
}
