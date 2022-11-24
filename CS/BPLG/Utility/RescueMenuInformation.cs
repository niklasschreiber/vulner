using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;

namespace BPLG.Utility
{
    public class GroupSectionConfiguration : ConfigurationSection
    {
        [ConfigurationProperty("MenuGroups")]
        [ConfigurationCollection(typeof(MenuGroupSectionConfigurationStateCollection), AddItemName="MenuGroup")]
        public MenuGroupSectionConfigurationStateCollection MenuGroups
        {
            get
            {
                return this["MenuGroups"] as MenuGroupSectionConfigurationStateCollection;
            }
        }
    }
    
    [ConfigurationCollection(typeof(MenuGroupSectionConfigurationState))]
    public class MenuGroupSectionConfigurationStateCollection : ConfigurationElementCollection
    {
        public MenuGroupSectionConfigurationState this[int index]
        {
            get
            {
                return base.BaseGet(index) as MenuGroupSectionConfigurationState;
            }
            set
            {
                if (base.BaseGet(index) != null) { base.BaseRemoveAt(index); }
                this.BaseAdd(index, value);
            }
        }

        protected override ConfigurationElement CreateNewElement()
        {
            return new MenuGroupSectionConfigurationState();
        }

        protected override object GetElementKey(ConfigurationElement element)
        {
            return ((MenuGroupSectionConfigurationState)element).Name;
        }
    }
    
    public class MenuGroupSectionConfigurationState : ConfigurationElement
    {
        [ConfigurationProperty("Name", IsRequired = true)]
        public string Name
        {
            get
            {
                return this["Name"] as string;
            }
        }

        [ConfigurationProperty("Label", IsRequired = true)]
        public string Label
        {
            get
            {
                return this["Label"] as string;
            }
        }

        [ConfigurationProperty("Link", IsRequired = true)]
        public string Link
        {
            get
            {
                return this["Link"] as string;
            }
        }

        [ConfigurationProperty("Order", IsRequired = true)]
        public string Order
        {
            get
            {
                //int orderItem = 0;
                //int.TryParse(this["Order"] as string, out orderItem);
                return this["Order"] as string;
            }
        }

        [ConfigurationProperty("Operation", IsRequired = true)]
        public string Operation
        {
            get
            {
                //int orderItem = 0;
                //int.TryParse(this["Order"] as string, out orderItem);
                return this["Operation"] as string;
            }
        }

        [ConfigurationProperty("DenyOperation", IsRequired = false)]
        public string DenyOperation
        {
            get
            {
                //int orderItem = 0;
                //int.TryParse(this["Order"] as string, out orderItem);
                return this["DenyOperation"] as string;
            }
        }

        [ConfigurationProperty("ForceRealUser", IsRequired = false)]
        public bool ForceRealUser
        {
            get
            {
                bool? forceRealUserTemp = this["ForceRealUser"] as bool?;
                return forceRealUserTemp != null ? (bool)forceRealUserTemp : false;
            }
        }

        [ConfigurationProperty("MenuItems")]
        public MenuSectionConfigurationStateCollection MenuItems
        {
            get
            {
                return this["MenuItems"] as MenuSectionConfigurationStateCollection;
            }
        }
    }

    [ConfigurationCollection(typeof(MenuSectionConfigurationState))]
    public class MenuSectionConfigurationStateCollection : ConfigurationElementCollection
    {
        public MenuSectionConfigurationState this[int index]
        {
            get
            {
                return base.BaseGet(index) as MenuSectionConfigurationState;
            }
            set
            {
                if (base.BaseGet(index) != null) { base.BaseRemoveAt(index); }
                this.BaseAdd(index, value);
            }
        }

        protected override ConfigurationElement CreateNewElement()
        {
            return new MenuSectionConfigurationState();
        }

        protected override object GetElementKey(ConfigurationElement element)
        {
            return ((MenuSectionConfigurationState)element).DisplayName;
        }
    }

    public class MenuSectionConfigurationState : ConfigurationElement
    {
        [ConfigurationProperty("DisplayName", IsRequired = true)]
        public string DisplayName
        {
            get
            {
                return this["DisplayName"] as string;
            }
        }

        [ConfigurationProperty("Link", IsRequired = true)]
        public string Link
        {
            get
            {
                return this["Link"] as string;
            }
        }

        [ConfigurationProperty("Visibility", IsRequired = true)]
        public bool Visibility
        {
            get
            {
                bool? visibleTemp = this["Visibility"] as bool?;
                return visibleTemp != null ? (bool)visibleTemp : false;
            }
        }

        [ConfigurationProperty("Target", IsRequired = true)]
        public string Target
        {
            get
            {
                return this["Target"] as string;
            }
        }

        [ConfigurationProperty("IsInternal", IsRequired = true)]
        public bool IsInternal
        {
            get
            {
                bool? internalTemp = this["IsInternal"] as bool?;
                return internalTemp != null ? (bool)internalTemp : false;
            }
        }

        [ConfigurationProperty("Operation", IsRequired = true)]
        public string Operation
        {
            get
            {
                return this["Operation"] as string;
            }
        }

        [ConfigurationProperty("ForceRealUser", IsRequired = false)]
        public bool ForceRealUser
        {
            get
            {
                bool? forceRealUserTemp = this["ForceRealUser"] as bool?;
                return forceRealUserTemp != null ? (bool)forceRealUserTemp : false;
            }
        }

        [ConfigurationProperty("Order", IsRequired = true)]
        public int Order
        {
            get
            {
                int orderItem = 0;
                int.TryParse(Convert.ToString(this["Order"]), out orderItem);
                return orderItem;
            }
        }
    }
    
    public class RescueMenuInformation
    {
        private GroupSectionConfiguration menuConfigInfo = null;

        public GroupSectionConfiguration MenuGroup 
        {
            get 
            {
                return menuConfigInfo;
            }
        }

        public RescueMenuInformation()
        {
            menuConfigInfo = (GroupSectionConfiguration)ConfigurationManager.GetSection("MenuList");
        }
    }
}
