using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Controls;
using PosteItaliane.ContactCenter.Common.UI;
using System.Windows;
using System.Reflection;
using PosteItaliane.ContactCenter.Common.Configuration;
using System.ComponentModel;
using PosteItaliane.ContactCenter.Common.Proxies.Entities;
using PosteItaliane.ContactCenter.Common.Properties;

namespace PosteItaliane.ContactCenter.Common.Interfaces
{
    [Serializable]
    public abstract class Controller
    {
        #region Private const
        const string RESOURCE_PATH = "/{0};component/{1}/{2}";
        const string IMAGE_PATH = "/{0};component/Images/{1}";
        #endregion

        #region Protected fields
        protected SmartClient186Operation[] controllerOpsConfig;
        private Dictionary<string, IVRManagedCode> ivrManagedCodes; 
        #endregion

        #region Protected constructor
        protected Controller(IContainer container)
        {
            this.Container = container;
        }
        #endregion

        #region Virtual method
        public virtual void Initialize(SmartClient186Operation[] controllerOpsConfig)
        {
            if (controllerOpsConfig != null)
            {
                this.controllerOpsConfig = controllerOpsConfig;

                ivrManagedCodes = (from op in controllerOpsConfig
                                   from ivrM in op.IVRManagedCodes
                                   select ivrM).ToDictionary(i => i.ManagedCode);
            }
        }
        #endregion

        #region Abstract method
        public abstract bool OnClosing();
        public abstract bool OnMaskChanging();
        public abstract void Close();
        public abstract void NewIncomingCallerInfo(IncomingCallerInfoRequest request);
        public abstract void NewOperationCompleteRequest(CompleteOperationRequest request);
        #endregion
        
        #region Public properties
        public IContainer Container { get; set; }

        public ContentControl HelpPane
        {
            get
            {
                return Container.SmartClient186Window.HelpPane;
            }
        }

        public ContentControl TaskPane
        {
            get
            {
                return Container.SmartClient186Window.TaskPane;
            }
        }

        public Control MenuPane
        {
            get
            {
                return Container.SmartClient186Window.MenuPane;
            }
        }

        public object MainPane
        {
            get
            {
                return Container.SmartClient186Window.MainPane;
            }
            protected set
            {
                Container.SmartClient186Window.MainPane = value;
            }
        }
        #endregion
        
        #region Protected methods
		        /// <summary>
        /// Returns a relative uri of images resources stored in Images assembly folder 
        /// </summary>
        /// <param name="imageName"></param>
        /// <returns></returns>
        protected Uri GetResourceImageUri(string imageName)
        {
            return new Uri(string.Format(IMAGE_PATH, this.GetType().Assembly.FullName, imageName), UriKind.Relative);
        }

        protected Uri GetResourceUri(string relativePath, string resourceName)
        {
            return new Uri(string.Format(RESOURCE_PATH, this.GetType().Assembly.FullName, relativePath, resourceName), UriKind.Relative);
        }

        protected SmartClient186Operation GetIvrManagedCodeInfo(string managedCode, out IVRManagedCode ivrManagedCode)
        {
            ivrManagedCode = null;

            foreach (var sc186OpConfig in controllerOpsConfig)
            {
                if (sc186OpConfig.IVRManagedCodes != null)
                {
                    ivrManagedCode = sc186OpConfig.IVRManagedCodes.FirstOrDefault(
                        ivr => string.Equals(ivr.ManagedCode, managedCode, StringComparison.InvariantCultureIgnoreCase));

                    if (ivrManagedCode != null)
                    {
                        return sc186OpConfig;
                    }
                }
            }

            return null;
        }

        protected void MessageToOperatorIncomingInfo(IOperationRequest operationRequest, IVRManagedCode ivrManagedCode, string reasonCode, string additionalInfo)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat(Resources.MessageToOperatorIncomingInfo,
                operationRequest.Cli, operationRequest.OloInfo.Description, ivrManagedCode.MessageToOperator);

            if(!string.IsNullOrEmpty(reasonCode))
            {
                IVRReasonCode ivrRC = PDLConfiguration.Current.IVRReasonCodes.FirstOrDefault(
                    rc => string.Equals(rc.ReasonCode, reasonCode, StringComparison.InvariantCultureIgnoreCase));

                if (ivrRC != null)
                {
                    sb.AppendLine();
                    sb.AppendFormat(Resources.MessageToOperatorReasonCode, ivrRC.ReasonCode, ivrRC.MessageToOperator);
                }
            }

            if (!string.IsNullOrEmpty(additionalInfo))
            {
                sb.AppendLine();
                sb.AppendFormat(Resources.MessageToOperatorReasonAdditionalInfo, additionalInfo);
            }

            sb.AppendLine();
            sb.Append(Resources.MessageToOperatorFooter);

            MessageBox186.ShowAsync(sb.ToString());
        }
	    #endregion    

        #region Public methods
        public bool IsManagedByController(string codeIVR)
        {
            if (this.controllerOpsConfig == null || this.controllerOpsConfig.Length == 0)
            {
                return false;
            }

            return this.ivrManagedCodes.ContainsKey(codeIVR);
        }
        #endregion
    }
}
