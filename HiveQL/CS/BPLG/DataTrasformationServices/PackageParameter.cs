using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using System.Web.Services;
using System.Xml;
using System.Collections.ObjectModel;

namespace BPLG.DataTrasformationServices
{
    /// <summary>
    /// This represents the all way to execute a DTSX package
    /// </summary>
    public enum ExecutionType
    {
        /// <summary>
        /// No execution has been chosen. The class will raise an Exception
        /// </summary>
        NotSpecified = 0,
        /// <summary>
        /// File System execution has been chosen
        /// </summary>
        FileSystem = 1,
        /// <summary>
        /// Sql Server execution has been chosen
        /// </summary>
        SqlServer = 2,
        /// <summary>
        /// Sql Agent execution has been chosen
        /// </summary>
        SqlAgent = 3
    }

    /// <summary>
    /// This represents the available result for execution
    /// </summary>
    public enum ExecutionResult
    {
        /// <summary>
        /// No execution result has been chosen.
        /// </summary>
        NotSpecified = 0,
        /// <summary>
        /// Message of error
        /// </summary>
        Error = 1,
        /// <summary>
        /// Message of success
        /// </summary>
        Success = 2,
    }

    /// <summary>
    /// This represents the available action allowd on package variables
    /// </summary>
    public enum VariableAction
    {
        /// <summary>
        /// No execution result has been chosen.
        /// </summary>
        NotSpecified = 0,
        /// <summary>
        /// Message of error
        /// </summary>
        Add = 1,
        /// <summary>
        /// Message of success
        /// </summary>
        Set = 2,
        /// <summary>
        /// Message of success
        /// </summary>
        Del = 3
    }

    /// <summary>
    /// This class allow caller to set an entire information about a specific DTSX has to be 
    /// execute by client
    /// </summary>
    public class PackageParameter
    {
        #region CTOR
        /// <summary>
        /// Default constructor for this class
        /// </summary>
        /// <example>This sample show how to call the PackageParameter class and use it
        /// <code>
        /// class TestClass
        /// {
        ///     WebServiceInstance ExecutePackage = new WebServiceInstance();
        ///     ExecutePackage.Timeout = -1;
        /// 
        ///     try 
        ///     {
        ///         PackageParameter PackageConfiguration = new PackageParameter(BPLG.DTSX2008.ExecutionType.[SqlServer|FileSystem|SqlAgent]);
        /// 
        ///         #region SQL SERVER EXECUTION
        ///         PackageConfiguration.SqlServer_Configuration.PackageName = "LibroCespiti-ImportDiscovererData";
        ///         PackageConfiguration.SqlServer_Configuration.PackagePath = @"\Standalone\";
        ///         PackageConfiguration.SqlServer_Configuration.ServerName = "YOUR_SERVER";
        ///         PackageConfiguration.SqlServer_Configuration.UserName = null;
        ///         PackageConfiguration.SqlServer_Configuration.Password = null;
        ///         #endregion SQL SERVER EXECUTION
        /// 
        ///         #region FILE SYSTEM EXECUTION
        ///         PackageConfiguration.FileSystem_Configuration.PackageName = "LibroCespiti-ImportDiscovererData.dtsx";
        ///         #endregion FILE SYSTEM EXECUTION
        /// 
        ///         #region SQL AGENT EXECUTION
        ///         PackageConfiguration.SqlAgent_Configuration.ServerName = "MISQL08P";
        ///         PackageConfiguration.SqlAgent_Configuration.JobName = "LibroCespiti";
        ///         #endregion SQL AGENT EXECUTION
        /// 
        ///         //To set a variable already presents on Sql Server package
        ///         PackageConfiguration.Variables["FileName"] = @"\\mifile01\gruppi\_transito\.....";
        /// 
        ///         //To add a variable to Sql Server package
        ///         PackageConfiguration.Variables.AddVariable("FileName", @"\\mifile01\gruppi\_transito\.....");
        /// 
        ///         if (PackageConfiguration.DeserializeResult(ExecutePackage.ExecutePackages(PackageConfiguration.SerializePackage())))
        ///         {
        ///             foreach (ExecutionResults ExecActual in PackageConfiguration.ExecutionResults)
        ///             {
        ///                 string Error = ExecActual.ExecutionMessage;
        ///             }
        ///         }
        ///     }
        ///     catch (KeyNotFoundException Ex)
        ///     {
        ///         //TODO
        ///     }
        /// }
        /// </code>
        /// </example>
        public PackageParameter(ExecutionType ExecutionType)
        {
            m_ExecutionType = ExecutionType;
        }

        /// <summary>
        /// Default constructor for this class
        /// </summary>
        /// <example>This sample show how to call the PackageParameter class and use it
        /// <code>
        /// class TestClass
        /// {
        ///     WebServiceInstance ExecutePackage = new WebServiceInstance();
        ///     ExecutePackage.Timeout = -1;
        /// 
        ///     try 
        ///     {
        ///         PackageParameter PackageConfiguration = new PackageParameter();
        /// 
        ///         #region SQL SERVER EXECUTION
        ///         PackageConfiguration.SqlServer_Configuration.PackageName = "LibroCespiti-ImportDiscovererData";
        ///         PackageConfiguration.SqlServer_Configuration.PackagePath = @"\Standalone\";
        ///         PackageConfiguration.SqlServer_Configuration.ServerName = "YOUR_SERVER";
        ///         PackageConfiguration.SqlServer_Configuration.UserName = null;
        ///         PackageConfiguration.SqlServer_Configuration.Password = null;
        ///         PackageParameter.ExecutionType = ExecutionType.SqlServer;
        ///         #endregion SQL SERVER EXECUTION
        /// 
        ///         #region FILE SYSTEM EXECUTION
        ///         PackageConfiguration.FileSystem_Configuration.PackageName = "LibroCespiti-ImportDiscovererData.dtsx";
        ///         PackageParameter.ExecutionType = ExecutionType.FileSystem;
        ///         #endregion FILE SYSTEM EXECUTION
        /// 
        ///         #region SQL AGENT EXECUTION
        ///         PackageConfiguration.SqlAgent_Configuration.ServerName = "MISQL08P";
        ///         PackageConfiguration.SqlAgent_Configuration.JobName = "LibroCespiti";
        ///         PackageParameter.ExecutionType = ExecutionType.SqlAgent;
        ///         #endregion SQL AGENT EXECUTION
        /// 
        ///         //To set a variable already presents on Sql Server package
        ///         PackageConfiguration.Variables["FileName"] = @"\\mifile01\gruppi\_transito\.....";
        /// 
        ///         //To add a variable to Sql Server package
        ///         PackageConfiguration.Variables.AddVariable("FileName", @"\\mifile01\gruppi\_transito\.....");
        /// 
        ///         if (PackageConfiguration.DeserializeResult(ExecutePackage.ExecutePackages(PackageConfiguration.SerializePackage())))
        ///         {
        ///             foreach (ExecutionResults ExecActual in PackageConfiguration.ExecutionResults)
        ///             {
        ///                 string Error = ExecActual.ExecutionMessage;
        ///             }
        ///         }
        ///     }
        ///     catch (KeyNotFoundException Ex)
        ///     {
        ///         //TODO
        ///     }
        /// }
        /// </code>
        /// </example>
        public PackageParameter()
        {
        }
        #endregion CTOR

        #region XPATH CONSTANT
        /// <summary>
        /// Path in order to get the Package name stored into this Package
        /// </summary>
        private static string XPath_PackageName = "//DI/PN";
        /// <summary>
        /// Path in order to get the Package Path stored into this Package
        /// </summary>
        private static string XPath_PackagePath = "//DI/PP";
        /// <summary>
        /// Path in order to get the Server name stored into this Package
        /// </summary>
        private static string XPath_ServerName = "//DI/SN";
        /// <summary>
        /// Path in order to get the UserName stored into this Package
        /// </summary>
        private static string XPath_UserName = "//DI/UN";
        /// <summary>
        /// Path in order to get the Password stored into this Package
        /// </summary>
        private static string XPath_Password = "//DI/PW";
        /// <summary>
        /// Path in order to get the JobName stored into this Package
        /// </summary>
        private static string XPath_JobName = "//DI/JN";
        /// <summary>
        /// Path in order to get the Package Configuration file stored into this Package
        /// </summary>
        private static string XPath_PackageConfiguration = "//DI/PC";
        /// <summary>
        /// Path in order to get the Execution type stored into this Package
        /// </summary>
        private static string XPath_ExecutionType = "//DI/ET";
        /// <summary>
        /// Path in order to get the Variable Item stored into this Package
        /// </summary>
        private static string XPath_Variables = "//VD/i";
        /// <summary>
        /// Path in order to get the Variable name stored into this Package
        /// </summary>
        private static string XPath_VariableName = "descendant::n";
        /// <summary>
        /// Path in order to get the Variable type stored into this Package
        /// </summary>
        private static string XPath_VariableType = "descendant::t";
        /// <summary>
        /// Path in order to get the Variable value stored into this Package
        /// </summary>
        private static string XPath_VariableValue = "descendant::v";
        /// <summary>
        /// Path in order to get the Variable action stored into this Package
        /// </summary>
        private static string XPath_VariableAction = "descendant::a";
        /// <summary>
        /// Path in order to get the Error value stored into this Package
        /// </summary>
        private static string XPath_ErrorValue = "//ES/e";
        #endregion XPATH CONSTANT

        #region VARIABLES
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private XmlDocument m_XmlDocument = null;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private ExecutionType m_ExecutionType = ExecutionType.NotSpecified;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private BPLG.DataTrasformationServices.Variables m_Variables = new BPLG.DataTrasformationServices.Variables();
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private List<ExecutionResults> m_ExecutionResults = new List<ExecutionResults>();
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private SqlServer_Configuration m_SqlServer_Configuration = new SqlServer_Configuration();
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private FileSystem_Configuration m_FileSystem_Configuration = new FileSystem_Configuration();
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private SqlAgent_Configuration m_SqlAgent_Configuration = new SqlAgent_Configuration();
        #endregion VARIABLES

        #region PARAMETERS
        /// <summary>
        /// This property is in charge to allow caller to access properties specific for
        /// Sql Server Agent Execution
        /// </summary>
        public SqlAgent_Configuration SqlAgent_Configuration
        {
            get
            {
                return m_SqlAgent_Configuration;
            }
            set
            {
                m_SqlAgent_Configuration = value;
            }
        }
        /// <summary>
        /// This property is in charge to allow caller to access properties specific for
        /// File System Execution
        /// </summary>
        public FileSystem_Configuration FileSystem_Configuration
        {
            get
            {
                return m_FileSystem_Configuration;
            }
            set
            {
                m_FileSystem_Configuration = value;
            }
        }
        /// <summary>
        /// This property is in charge to allow caller to access properties specific for 
        /// Sql Server Execution
        /// </summary>
        public SqlServer_Configuration SqlServer_Configuration
        {
            get
            {
                return m_SqlServer_Configuration;
            }
            set
            {
                m_SqlServer_Configuration = value;
            }
        }
        /// <summary>
        /// This parameter it will be used to specify an execution way for this DTSX.
        /// </summary>
        /// <para></para>
        /// <para>FileSystem: the DTSX package is located on filesystem and it will be execute directly
        /// on the machine. It is possible to Specify parameter</para>
        /// <para>SqlServer: DTSX package is hosted on SQL Server machine and it will be loaded from
        /// that machine and it will be executed locally. It is possible to specify Parameter</para>
        /// <para>SqlAgent: DTSX package is hosted on SQL Server machine but it will run on that machine
        /// in a remote way. To make it start, it will launch a Sql Server Job. This Job must be
        /// create before to execute DTSX</para>
        public ExecutionType ExecutionType
        {
            get
            {
                return m_ExecutionType;
            }
            set
            {
                m_ExecutionType = value;
            }
        }
        /// <summary>
        /// This parameter allow caller to obtain an object represents a Variables class
        /// </summary>
        public Variables Variables
        {
            get
            {
                return m_Variables;
            }
        }
        /// <summary>
        /// This parameter allow caller to obtain an object represents an ExecutionResult
        /// class
        /// </summary>
        public ReadOnlyCollection<ExecutionResults> ExecutionResults
        {
            get
            {
                return new ReadOnlyCollection<ExecutionResults>(m_ExecutionResults);
            }
        }
        #endregion PARAMETERS

        #region METHODS
        /// <summary>
        /// This method could be used in order to get a serializable version of this
        /// Package object. All information presents in this class will be serialized and
        /// an XML string will be returned so the caller would be able to sent this object
        /// to webservice to be deserialized
        /// </summary>
        /// <returns>String represents this object</returns>
        /// <remarks>It is important to know that the only way to send a PackageParameter object
        /// to the webservice is to Serilize it
        /// </remarks>
        /// <example>A sample to use this method
        /// <code>
        /// class TestClass
        /// {
        ///     public TestMethod() 
        ///     {
        ///         PackageParameter PackageConfiguration = new PackageParameter();
        ///         //TODO Setting all information for Package
        ///         ...
        ///         ...
        ///         ...
        ///         string SerializedString = PackageConfiguration.SerializePackage();
        ///     }
        /// }
        /// </code>
        /// </example>
        public string SerializePackage()
        {
            try
            {
                m_XmlDocument = new XmlDocument();
                XmlElement RootNode = m_XmlDocument.CreateElement("r");
                m_XmlDocument.AppendChild(RootNode);

                #region INFO NODES
                XmlElement DTSXInfo = m_XmlDocument.CreateElement("DI");

                XmlElement XPackageName = m_XmlDocument.CreateElement("PN");
                XmlElement XPackagePath = m_XmlDocument.CreateElement("PP");
                XmlElement XServerName = m_XmlDocument.CreateElement("SN");
                XmlElement XUserName = m_XmlDocument.CreateElement("UN");
                XmlElement XPassword = m_XmlDocument.CreateElement("PW");
                XmlElement XJobName = m_XmlDocument.CreateElement("JN");
                XmlElement XPackageConfiguration = m_XmlDocument.CreateElement("PC");
                XmlElement XExecutionType = m_XmlDocument.CreateElement("ET");

                switch (m_ExecutionType)
                {
                    case ExecutionType.SqlServer:
                        XPackageName.AppendChild(m_XmlDocument.CreateCDataSection(m_SqlServer_Configuration.PackageName));
                        XPackagePath.AppendChild(m_XmlDocument.CreateCDataSection(m_SqlServer_Configuration.PackagePath));
                        XServerName.AppendChild(m_XmlDocument.CreateCDataSection(m_SqlServer_Configuration.ServerName));
                        XUserName.AppendChild(m_XmlDocument.CreateCDataSection(m_SqlServer_Configuration.UserName));
                        XPassword.AppendChild(m_XmlDocument.CreateCDataSection(m_SqlServer_Configuration.Password));
                        break;
                    case ExecutionType.FileSystem:
                        XPackageName.AppendChild(m_XmlDocument.CreateCDataSection(m_FileSystem_Configuration.PackageName));
                        XPackageConfiguration.AppendChild(m_XmlDocument.CreateCDataSection(m_FileSystem_Configuration.ConfigurationFile));
                        break;
                    case ExecutionType.SqlAgent:
                        XServerName.AppendChild(m_XmlDocument.CreateCDataSection(m_SqlAgent_Configuration.ServerName));
                        XJobName.AppendChild(m_XmlDocument.CreateCDataSection(m_SqlAgent_Configuration.JobName));
                        break;
                }
                XExecutionType.AppendChild(m_XmlDocument.CreateCDataSection(m_ExecutionType.ToString()));

                DTSXInfo.AppendChild(XPackageName);
                DTSXInfo.AppendChild(XPackagePath);
                DTSXInfo.AppendChild(XServerName);
                DTSXInfo.AppendChild(XUserName);
                DTSXInfo.AppendChild(XPassword);
                DTSXInfo.AppendChild(XJobName);
                DTSXInfo.AppendChild(XPackageConfiguration);
                DTSXInfo.AppendChild(XExecutionType);

                RootNode.AppendChild(DTSXInfo);
                #endregion INFO NODES

                #region INFO VARIABLES
                XmlElement VariableDeclared = m_XmlDocument.CreateElement("VD");

                foreach (Variable ActualVariable in m_Variables.Lists)
                {
                    XmlElement ItemNode = m_XmlDocument.CreateElement("i");
                    XmlElement NameNode = m_XmlDocument.CreateElement("n");
                    XmlElement TypeNode = m_XmlDocument.CreateElement("t");
                    XmlElement ValueNode = m_XmlDocument.CreateElement("v");
                    XmlElement ActionNode = m_XmlDocument.CreateElement("a");

                    NameNode.AppendChild(m_XmlDocument.CreateCDataSection(ActualVariable.VariableName));
                    TypeNode.AppendChild(m_XmlDocument.CreateCDataSection(ActualVariable.TypeUsato.ToString()));
                    ValueNode.AppendChild(m_XmlDocument.CreateCDataSection(Convert.ToString(ActualVariable.VariableValue).ToLower()));
                    ActionNode.AppendChild(m_XmlDocument.CreateCDataSection(ActualVariable.VariableAction.ToString()));

                    ItemNode.AppendChild(NameNode);
                    ItemNode.AppendChild(TypeNode);
                    ItemNode.AppendChild(ValueNode);
                    ItemNode.AppendChild(ActionNode);

                    VariableDeclared.AppendChild(ItemNode);
                }
                RootNode.AppendChild(VariableDeclared);
                #endregion INFO VARIABLES

                return m_XmlDocument.OuterXml;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
            
        }
        /// <summary>
        /// This method is in charge to receive a string in input that represents an instance
        /// of PackageParameter object serialized and it will fill this instance with all
        /// data were presents in the original copy of the object
        /// </summary>
        /// <param name="SerializedObject">A string that represents an instance serialized</param>
        /// <example>A sample to use this method
        /// <code>
        /// class TestClass
        /// {
        ///     public TestMethod(string SerializedObject) 
        ///     {
        ///         PackageParameter PackageConfiguration = new PackageParameter();
        ///         PackageConfiguration.DeserializePackage(SerializedObject);
        ///     }
        /// }
        /// </code>
        /// </example>
        public void DeserializePackage(string SerializedObject)
        {
            try
            {
                m_XmlDocument = new XmlDocument();
                m_XmlDocument.LoadXml(SerializedObject);

                ExecutionType = (ExecutionType)Enum.Parse(typeof(ExecutionType), m_XmlDocument.SelectSingleNode(XPath_ExecutionType).InnerText);

                switch (ExecutionType)
                {
                    case ExecutionType.SqlServer:
                        m_SqlServer_Configuration.PackageName = m_XmlDocument.SelectSingleNode(XPath_PackageName).InnerText;
                        m_SqlServer_Configuration.PackagePath = m_XmlDocument.SelectSingleNode(XPath_PackagePath).InnerText;
                        m_SqlServer_Configuration.ServerName = m_XmlDocument.SelectSingleNode(XPath_ServerName).InnerText;
                        m_SqlServer_Configuration.UserName = m_XmlDocument.SelectSingleNode(XPath_UserName).InnerText;
                        m_SqlServer_Configuration.Password = m_XmlDocument.SelectSingleNode(XPath_Password).InnerText;
                        break;
                    case ExecutionType.FileSystem:
                        m_FileSystem_Configuration.PackageName = m_XmlDocument.SelectSingleNode(XPath_PackageName).InnerText;
                        m_FileSystem_Configuration.ConfigurationFile = m_XmlDocument.SelectSingleNode(XPath_PackageConfiguration).InnerText;
                        break;
                    case ExecutionType.SqlAgent:
                        m_SqlAgent_Configuration.ServerName = m_XmlDocument.SelectSingleNode(XPath_ServerName).InnerText;
                        m_SqlAgent_Configuration.JobName = m_XmlDocument.SelectSingleNode(XPath_JobName).InnerText;
                        break;
                }
                

                XmlNodeList NodeList = m_XmlDocument.SelectNodes(XPath_Variables);
                foreach (XmlNode ActualNode in NodeList)
                {
                    this.Variables.AddVariable(ActualNode.SelectSingleNode(XPath_VariableName).InnerText
                                                , ActualNode.SelectSingleNode(XPath_VariableValue).InnerText
                                                , Type.GetType(ActualNode.SelectSingleNode(XPath_VariableType).InnerText)
                                                , (VariableAction)Enum.Parse(typeof(VariableAction), ActualNode.SelectSingleNode(XPath_VariableAction).InnerText)
                                                );
                }
                m_XmlDocument = null;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }
        /// <summary>
        /// This method is in charge to serialize all result arrived by the execution of
        /// the DTSX. this method will be used mainly by the webservice will execute the package
        /// and, in order to inform the caller about the execution result, the webservice is going
        /// to use this method so it would be able to send back to the caller an XML string with
        /// all information. This information could be managed by the caller just using the 
        /// "DeserializeResult" method
        /// </summary>
        /// <param name="Result">Generic collection with all error generated by DTSX Execution</param>
        /// <returns>The string contains all error serialized</returns>
        public string SerializeResult(List<string> Result)
        {
            if (Result != null)
            {
                try
                {
                    m_XmlDocument = new XmlDocument();
                    XmlNode RootNode = m_XmlDocument.CreateElement("r");
                    XmlNode ErrorSection = m_XmlDocument.CreateElement("ES");
                    foreach (string ActualError in Result)
                    {
                        XmlNode ErrorElement = m_XmlDocument.CreateElement("e");
                        ErrorElement.AppendChild(m_XmlDocument.CreateCDataSection(ActualError));
                        ErrorSection.AppendChild(ErrorElement);
                    }
                    RootNode.AppendChild(ErrorSection);
                    m_XmlDocument.AppendChild(RootNode);
                    return m_XmlDocument.OuterXml;
                }
                catch (Exception Ex)
                {
                    throw Ex;
                }
            }
            else
            {
                return string.Empty;
            }
        }
        /// <summary>
        /// This method is in charge to fill this inctance of object with all information returned
        /// by the DTSX Execution on webservice side. After this operation, caller will be able to
        /// scroll all information by using "ExecutionResults" parameter
        /// </summary>
        /// <param name="SerializedResult">The sring with serialized result information</param>
        /// <returns>True is there are some error otherwise false</returns>
        public bool DeserializeResult(string SerializedResult)
        {
            if (!string.IsNullOrEmpty(SerializedResult))
            {
                try
                {
                    m_XmlDocument = new XmlDocument();
                    m_XmlDocument.LoadXml(SerializedResult);

                    foreach (XmlNode ActualNode in m_XmlDocument.SelectNodes(XPath_ErrorValue))
                    {
                        m_ExecutionResults.Add(new ExecutionResults(ActualNode.InnerText, ExecutionResult.Error));
                    }
                    m_XmlDocument = null;
                    return true;
                }
                catch (Exception Ex)
                {
                    throw Ex;
                }
            }
            return false;
        }
        #endregion METHODS
    }

    /// <summary>
    /// This class is used to specialized parameter just for execution with Load from SQL Server 
    /// way. In this way this class will be able to check parameter and play a Business Logic role
    /// </summary>
    public class SqlServer_Configuration
    {
        internal SqlServer_Configuration()
        {

        }

        #region VARIABLES
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_PackageName = string.Empty;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_PackagePath = string.Empty;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_ServerName = string.Empty;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_UserName = null;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_Password = null;
        #endregion VARIABLES

        #region PARAMETERS
        /// <summary>
        /// This property allow caller to specify the Package Name. This name is just the name of
        /// the Package DTSX without its Path. If it will be necessary to specify a path it should 
        /// be done by using the property PACKAGEPATH
        /// </summary>
        /// <para>PackageParameter.PackageName = "DTSXToLoad";</para>
        public string PackageName
        {
            get
            {
                return m_PackageName;
            }
            set
            {
                m_PackageName = value;
            }
        }
        /// <summary>
        /// This properties is used just to specify a DTSX Path in case there is. 
        /// For FileSystem Execution it's always necessary to specify a path
        /// </summary>
        /// <para>C:\FolderContainer\ListDTSX\</para>
        /// <para>\DTSXFolderOnSql\</para>
        public string PackagePath
        {
            get
            {
                return m_PackagePath;
            }
            set
            {
                m_PackagePath = value;
            }
        }
        /// <summary>
        /// This property represents the SQL Server on which the DTSX is hosted. 
        /// This property will be considered just in case the ExecutionType specified 
        /// is "SqlServer"
        /// </summary>
        public string ServerName
        {
            get
            {
                return m_ServerName;
            }
            set
            {
                m_ServerName = value;
            }
        }
        /// <summary>
        /// This peoperty allow caller to specify a specific Username it will be
        /// used to make run DTSX. Do not use it to make DTSX run with locally account
        /// domain user
        /// </summary>
        public string UserName
        {
            get
            {
                return m_UserName;
            }
            set
            {
                m_UserName = string.IsNullOrEmpty(value) ? null : value;
            }
        }
        /// <summary>
        /// This peoperty is used to specify a Password associated to the Username 
        /// given.
        /// </summary>
        public string Password
        {
            get
            {
                return m_Password;
            }
            set
            {
                m_Password = string.IsNullOrEmpty(value) ? null : value;
            }
        }
        #endregion PARAMETERS
    }

    /// <summary>
    /// This class is used to specialized parameter just for execution with Load from SQL Server 
    /// way. In this way this class will be able to check parameter and play a Business Logic role
    /// </summary>
    public class FileSystem_Configuration
    {
        internal FileSystem_Configuration()
        {

        }

        #region VARIABLES
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_PackageName = string.Empty;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_ConfigurationFile = string.Empty;
        #endregion VARIABLES

        #region PARAMETERS
        /// <summary>
        /// This property allow caller to specify the Package Name. This name is just the name of
        /// the Package DTSX without its Path. If it will be necessary to specify a path it should 
        /// be done by using the property PACKAGEPATH
        /// </summary>
        /// <para>PackageParameter.PackageName = "DTSXToLoad";</para>
        public string PackageName
        {
            get
            {
                return m_PackageName;
            }
            set
            {
                m_PackageName = value;
            }
        }
        /// <summary>
        /// This property allow caller to specify the Configuration File Name. This name is just the name of
        /// the Configuration file without its Path. If it will be necessary to specify a path it should 
        /// be done by using the property PACKAGEPATH
        /// </summary>
        /// <para>PackageParameter.ConfigurationFile = "AssuranceSSISConfig.dtsConfig";</para>
        public string ConfigurationFile
        {
            get
            {
                return m_ConfigurationFile;
            }
            set
            {
                m_ConfigurationFile = (string.IsNullOrEmpty(value) ? null : value);
            }
        }
        #endregion PARAMETERS
    }

    /// <summary>
    /// This class is used to specialized parameter just for execution launching job through Sql Agent. 
    /// In this way this class will be able to check parameter and play a Business Logic role
    /// </summary>
    public class SqlAgent_Configuration
    {
        internal SqlAgent_Configuration()
        {

        }

        #region VARIABLES
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_ServerName = string.Empty;
        /// <summary>
        /// All information reserved for the developer
        /// </summary>
        private string m_JobName = string.Empty;
        #endregion VARIABLES

        #region PARAMETERS
        /// <summary>
        /// This property represents the SQL Server on which the Sql agent is running. 
        /// This property will be considered just in case the ExecutionType specified 
        /// is "SqlAgent"
        /// </summary>
        public string ServerName
        {
            get
            {
                return m_ServerName;
            }
            set
            {
                m_ServerName = value;
            }
        }
        /// <summary>
        /// This property represents the job name will be launched. 
        /// </summary>
        public string JobName
        {
            get
            {
                return m_JobName;
            }
            set
            {
                m_JobName = value;
            }
        }
        #endregion PARAMETERS
    }

    /// <summary>
    /// This class represents the list of execution result for the DTSX. It will be exposed
    /// through the PackageParameter class by using a ReadOnly List collection
    /// </summary>
    public class ExecutionResults
    {
        #region VARIABLES
        private string m_ExecutionMessage = string.Empty;
        private ExecutionResult m_ExecutionResult = ExecutionResult.NotSpecified;
        #endregion VARIABLES

        #region PARAMETERS
        /// <summary>
        /// This parameter allow caller to get the Execution Message returned by DTSX computing
        /// </summary>
        public string ExecutionMessage
        {
            get
            {
                return m_ExecutionMessage;
            }
            internal set
            {
                m_ExecutionMessage = value;
            }
        }
        /// <summary>
        /// This is an Enumeration that specify the kind of Message returned by DTSX computing
        /// </summary>
        public ExecutionResult ExecutionResult
        {
            get
            {
                return m_ExecutionResult;
            }
            internal set
            {
                m_ExecutionResult = value;
            }
        }
        #endregion PARAMETERS

        #region CTOR
        internal ExecutionResults(string ExecutionMessage, ExecutionResult ExecutionResult)
        {
            this.m_ExecutionMessage = ExecutionMessage;
            this.m_ExecutionResult = ExecutionResult;
        }
        #endregion CTOR
    }

    /// <summary>
    /// This class represents the list of variables added to the package
    /// </summary>
    public class Variables
    {
        #region VARS
        private List<Variable> ListaVariables = new List<Variable>();
        #endregion VARS

        #region CTOR
        internal Variables()
        {
        }
        #endregion CTOR

        #region PROPERTIES
        /// <summary>
        /// Get the Variable referenced by its name if its exists otherwise it will
        /// throw a System.Collections.Generic.KeyNotFoundException 
        /// </summary>
        /// <param name="Nomevariabile">Name of the key to lookup</param>
        /// <returns>Value stored for the given key</returns>
        [Obsolete("This property cannot be used because it doesn't match DTX Variables types")]
        private object this[string Nomevariabile]
        {
            get
            {
                #region CHECK IF ALREADY EXISTS
                Variable ActualVariable = CheckIfExist(Nomevariabile);
                #endregion CHECK IF ALREADY EXISTS
                #region GETTING VALUES
                if (ActualVariable == null)
                {
                    throw new KeyNotFoundException("The given key was not present in the list");
                }
                try
                {
                    if (ActualVariable.TypeUsato == typeof(int))
                    {
                        return (int)ActualVariable.VariableValue;
                    }
                    if (ActualVariable.TypeUsato == typeof(string))
                    {
                        return (string)ActualVariable.VariableValue;
                    }
                    if (ActualVariable.TypeUsato == typeof(object))
                    {
                        return ActualVariable.VariableValue;
                    }
                    return null;
                }
                catch (Exception Ex)
                {
                    return null;
                }
                #endregion GETTING VALUES
            }
            set
            {
                #region CHECK IF ALREADY EXISTS
                Variable ActualVariable = CheckIfExist(Nomevariabile);
                #endregion CHECK IF ALREADY EXISTS
                #region SET VARIABLE
                if (ActualVariable == null)
                {
                    AddVariable(Nomevariabile, value, VariableAction.Set);
                }
                else
                {
                    #region SETTING VALUES
                    try
                    {
                        if (ActualVariable.TypeUsato == typeof(int))
                        {
                            ActualVariable.VariableValue = (int)value;
                        }
                        if (ActualVariable.TypeUsato == typeof(string))
                        {
                            ActualVariable.VariableValue = (string)value;
                        }
                        if (ActualVariable.TypeUsato == typeof(object))
                        {
                            ActualVariable.VariableValue = value;
                        }
                    }
                    catch (Exception Ex)
                    {

                    }
                    #endregion SETTING VALUES
                }
                #endregion SET VARIABLE
            }
        }
        /// <summary>
        /// This properties allow caller to iterate on the collection of Variables
        /// </summary>
        public IEnumerable<Variable> Lists
        {
            get
            {
                foreach (Variable ActualVar in ListaVariables)
                {
                    yield return ActualVar;
                }
            }
        }
        #endregion PROPERTIES

        #region METHOD SET VARIABLES
        #region PUBLIC VISIBILITY
        #region ADD VARIABLES
        /// <summary>
        /// This method allow you to add an object variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Object VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(object), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a string variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, String VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(string), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add an int variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Int32 VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(int), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Boolean variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Boolean VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Boolean), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Decimal variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Decimal VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Decimal), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Byte variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Byte VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Byte), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Char variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Char VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Char), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a DBNull variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, DBNull VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(DBNull), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Double variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Double VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Double), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Int16 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Int16 VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Int16), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Int64 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Int64 VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Int64), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a SByte variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, SByte VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(SByte), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a Single variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, Single VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Single), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a UInt32 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, UInt32 VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(UInt32), VariableValue, VariableAction.Add));
        }
        /// <summary>
        /// This method allow you to add a UInt64 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void AddVariable(string VariableName, UInt64 VariableValue)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(UInt64), VariableValue, VariableAction.Add));
        }

        #endregion ADD VARIABLES
        #region SET VARIABLES
        /// <summary>
        /// This method allow you to set an object variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Object VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(object), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a string variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, String VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(string), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set an int variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Int32 VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(int), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a Boolean variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Boolean VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Boolean), VariableValue, VariableAction.Set));
            
        }
        /// <summary>
        /// This method allow you to set a Decimal variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Decimal VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Decimal), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a Byte variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Byte VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Byte), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a Char variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Char VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Char), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a DBNull variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, DBNull VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(DBNull), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a Double variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Double VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Double), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a Int16 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Int16 VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Int16), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a Int64 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Int64 VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Int64), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a SByte variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, SByte VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(SByte), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a Single variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, Single VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Single), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a UInt32 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, UInt32 VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(UInt32), VariableValue, VariableAction.Set));
        }
        /// <summary>
        /// This method allow you to set a UInt64 variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        public void SetVariable(string VariableName, UInt64 VariableValue)
        {
            Variable VariableFounded = CheckIfExist(VariableName);
            if (VariableFounded != null)
            {
                ListaVariables.Remove(VariableFounded);
            }
            ListaVariables.Add(new Variable(VariableName, typeof(UInt64), VariableValue, VariableAction.Set));
        }

        #endregion SET VARIABLES
        #endregion PUBLIC VISIBILITY
        #region INTERNAL VISIBILITY
        /// <summary>
        /// This method is in charge to allow internal class PackageParameter to specify a variable
        /// that should be imported in DTSX variables without add it but just by setting it
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        /// <param name="VariableAction">Variable action choosen</param>


        /// <summary>
        /// This method allow you to add an object variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        /// <param name="VariableAction">Action to do</param>
        internal void AddVariable(string VariableName, object VariableValue, VariableAction VariableAction)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(object), VariableValue, VariableAction));
        }
        /// <summary>
        /// This method allow you to add a string variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        /// /// <param name="VariableAction">Action to do</param>
        internal void AddVariable(string VariableName, string VariableValue, VariableAction VariableAction)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(string), VariableValue, VariableAction));
        }
        /// <summary>
        /// This method allow you to add an int variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        /// /// <param name="VariableAction">Action to do</param>
        internal void AddVariable(string VariableName, int VariableValue, VariableAction VariableAction)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(int), VariableValue, VariableAction));
        }
        /// <summary>
        /// This method allow you to add a Boolean variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        /// /// <param name="VariableAction">Action to do</param>
        internal void AddVariable(string VariableName, Boolean VariableValue, VariableAction VariableAction)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Boolean), VariableValue, VariableAction));
        }
        /// <summary>
        /// This method allow you to add a Decimal variable giving its a name and a value
        /// </summary>
        /// <param name="VariableName">Variable name</param>
        /// <param name="VariableValue">Variable value</param>
        /// /// <param name="VariableAction">Action to do</param>
        internal void AddVariable(string VariableName, Decimal VariableValue, VariableAction VariableAction)
        {
            if (CheckIfExist(VariableName) != null)
            {
                throw new ArgumentException("An element with the same key already exists in the list");
            }
            ListaVariables.Add(new Variable(VariableName, typeof(Decimal), VariableValue, VariableAction));
        }
        internal void AddVariable(string VariableName, object VariableValue, Type TypeSelected, VariableAction VariableAction)
        {
            switch (Type.GetTypeCode(TypeSelected))
            {
                case TypeCode.String:
                    AddVariable(VariableName, Convert.ToString(VariableValue), VariableAction);
                    break;
                case TypeCode.Int32:
                    AddVariable(VariableName, Convert.ToInt32(VariableValue), VariableAction);
                    break;
                case TypeCode.Boolean:
                    AddVariable(VariableName, Convert.ToBoolean(VariableValue), VariableAction);
                    break;
                case TypeCode.Decimal:
                    AddVariable(VariableName, Convert.ToDecimal(VariableValue), VariableAction);
                    break;
                default:
                    AddVariable(VariableName, VariableValue, VariableAction);
                    break;
            }
        }
        #endregion INTERNAL VISIBILITY
        #endregion METHOD SET VARIABLES

        #region USEFULL METHODS
        /// <summary>
        /// This method is in charge to delete all Variables already stored
        /// </summary>
        public void Clear()
        {
            ListaVariables.Clear();
        }
        /// <summary>
        /// This method will delete a specific item by using the name of the variables
        /// </summary>
        /// <param name="VariableName"></param>
        public void Remove(string VariableName)
        {
            Variable ActualVariable = ListaVariables.Find(delegate(Variable InternalVariable)
                {
                    return InternalVariable.VariableName == VariableName;
                });
            if (ActualVariable != null)
            {
                ListaVariables.Remove(ActualVariable);
            }
        }

        private Variable CheckIfExist(string VariableName)
        {
            return ListaVariables.Find(delegate(Variable InternalVariable)
            {
                return InternalVariable.VariableName == VariableName;
            });
        }
        #endregion USEFULL METHODS
    }

    /// <summary>
    /// This class represents every single variable added to the package
    /// </summary>
    public class Variable
    {
        private string m_VariableName = string.Empty;
        private Type m_TypeUsato = null;
        private object m_VariableValue = null;
        private VariableAction m_VariableAction = VariableAction.NotSpecified;

        internal Type TypeUsato
        {
            get
            {
                return m_TypeUsato;
            }
            set
            {
                m_TypeUsato = value;
            }
        }
        public string VariableName
        {
            get
            {
                return m_VariableName;
            }
        }
        public object VariableValue
        {
            get
            {
                return m_VariableValue;
            }
            set
            {
                m_VariableValue = value;
            }
        }
        public VariableAction VariableAction
        {
            get
            {
                return m_VariableAction;
            }
        }

        private Variable()
        {
        }
        internal Variable(string NomeVariabile, Type TipoVariabile, object ValoreVariabile, VariableAction VariableAction)
        {
            m_VariableName = NomeVariabile;
            m_TypeUsato = TipoVariabile;
            m_VariableValue = ValoreVariabile;
            m_VariableAction = VariableAction;
        }
    }

    /// <summary>
    /// This class will manage the Exception when the caller didn't specified any kind of
    /// execution type. In this case the package execution will be stopped and will be raised
    /// this kind of exception
    /// </summary>
    class NotExecutionTypeSpecified : Exception
    {
        public NotExecutionTypeSpecified() : base()
        {
        }

        public NotExecutionTypeSpecified(string Message) : base(Message)
        {
        }

        public NotExecutionTypeSpecified(string Message, Exception InnerException) : base(Message, InnerException)
        {
        }
    }
}
