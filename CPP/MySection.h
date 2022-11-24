#include "ListsElementCollection.h"

namespace testAppConfig
{
	ref class MySection : ConfigurationSection
	{
	private:
		static ConfigurationPropertyCollection ^_proprietes;
		static ConfigurationProperty ^_lists;

	public:
		static MySection()
		{
			_lists = gcnew ConfigurationProperty("", ListsElementCollection::typeid, nullptr, 
					ConfigurationPropertyOptions::IsRequired | ConfigurationPropertyOptions::IsDefaultCollection);
			_proprietes = gcnew ConfigurationPropertyCollection();
			_proprietes->Add(_lists);
		}

		property ListsElementCollection^ Lists
		{
			ListsElementCollection^ get() { return (ListsElementCollection^)this[_lists]; }
		}

		property virtual ListElement^ default[String ^]
		{
			ListElement^ get (String ^name) { return Lists[name]; }
		}

	protected :
		property virtual ConfigurationPropertyCollection ^Properties
		{
			ConfigurationPropertyCollection^get() override { return _proprietes; }
		}
	};
}