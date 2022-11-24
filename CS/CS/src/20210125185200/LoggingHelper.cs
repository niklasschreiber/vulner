using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Diagnostics;
using System.Reflection;
using System.Threading;
using System.IO;
using Microsoft.Practices.EnterpriseLibrary.Logging;
using Microsoft.Practices.EnterpriseLibrary.ExceptionHandling;

namespace PosteItaliane.ContactCenter.Common.Utility
{
    public class LoggingHelper
    {
        #region Public const
        public const string METHOD_ENTRY = "Entry";
        public const string METHOD_EXIT = "Exit";
        #endregion

        public static void WriteLogEntry(Exception ex)
        {
            WriteEntry(Resources.DefaultLoggingCategorySource, ex.ToString(), TraceEventType.Error);
        }

        #region Public Static Methods
        /// <summary>
        /// Writes a new log entry. 
        /// </summary>
        /// <param name="message">The content of the message.</param>
        /// <param name="severity">The severity of the message.</param>
        public static void WriteLogEntry(string message, TraceEventType severity)
        {
            WriteEntry(Resources.DefaultLoggingCategorySource, message, severity);
        }

        /// <summary>
        /// Writes a new log entry. 
        /// </summary>
        public static void WriteLogEntry(string softwareElement, string methodSignature, string message, TraceEventType severity)
        {
            WriteEntry(Resources.DefaultLoggingCategorySource, string.Format("{0}::{1} - {2}", softwareElement, methodSignature, message), severity);
        }

        /// <summary>
        /// Writes a new log entry. 
        /// </summary>
        public static void WriteLogEntry(string softwareElement, string methodSignature, string message)
        {
            WriteEntry(Resources.DefaultLoggingCategorySource, string.Format("{0}::{1} - {2}", softwareElement, methodSignature, message), TraceEventType.Error);
        }

        /// <summary>
        /// Writes a new entry in the trace.
        /// </summary>
        /// <param name="message">The content of the message.</param>
        public static void WriteTraceEntry(string message)
        {
            WriteEntry(Resources.DefaultTracingCategorySource, message, TraceEventType.Information);
        }

        /// <summary>
        /// Writes a new entry in the trace.
        /// </summary>
        /// <param name="format">A composite formate string</param>
        /// <param name="args">An Object array containing zero or more objects to format.</param>
        public static void WriteFormatTraceEntry(string format, params object[] args)
        {
            WriteEntry(Resources.DefaultTracingCategorySource, string.Format(format, args), TraceEventType.Information);
        }


        ///<summary>
        ///Writes a new entry in the trace.
        ///</summary>
        public static void WriteTraceEntry(string softwareElement, string methodSignature)
        {
            WriteEntry(Resources.DefaultTracingCategorySource, string.Format("{0}::{1}", softwareElement, methodSignature), TraceEventType.Information);
        }

        /// <summary>
        /// Writes a new entry in the trace.
        /// </summary>
        public static void WriteTraceEntry(string softwareElement, string methodSignature, string message)
        {
            WriteEntry(Resources.DefaultTracingCategorySource, string.Format("{0}::{1} - {2}", softwareElement, methodSignature, message), TraceEventType.Information);
        }

        #endregion

        #region Private Static Methods

        /// <summary>
        /// Writes a new entry in the specified log category.
        /// </summary>
        /// <param name="category">The log category.</param>
        /// <param name="message">The content of the message.</param>
        /// <param name="severity">The severity of the message.</param>
        /// <param name="getTitleUsingStackTrace">The entry's Title will be infered from StackTrace and Reflection</param>
        private static void WriteEntry(string category, string message, TraceEventType severity)
        {
            try
            {
                if (string.IsNullOrEmpty(category) ||
                    string.IsNullOrEmpty(message))
                {
                    return;
                }
                StackTrace stackTrace;
                StackFrame stackFrame;
                MethodBase methodBase = null;
                try
                {
                    stackTrace = new StackTrace();
                    stackFrame = stackTrace.GetFrame(2);
                    methodBase = stackFrame.GetMethod();
                }
                catch (Exception)
                {
                }
                LogEntry logEntry = new LogEntry();
                if (methodBase != null)
                {
                    if (methodBase.IsPrivate)
                    {
                        logEntry.Title = string.Format(Resources.PrivateActivityIdFormat, methodBase.ReflectedType.Name, methodBase.Name);
                    }
                    else
                    {
                        logEntry.Title = string.Format(Resources.ActivityIdFormat, methodBase.ReflectedType.Name, methodBase.Name);
                    }
                }
                else
                {
                    logEntry.Title = Resources.Unknown;
                }

#if DEBUG
                WaitCallback callBack = delegate
                {
                    Debug.WriteLine(String.Format("{0}-{1}", logEntry.Title, message));
                };
                ThreadPool.QueueUserWorkItem(callBack);
#endif

                logEntry.Categories.Add(category);
                logEntry.EventId = 300;
                logEntry.Message = ReplaceCharacters(message);
                logEntry.Severity = severity;
                logEntry.Priority = 5;
                logEntry.ProcessName = Path.GetFileName(logEntry.ProcessName);
                Logger.Write(logEntry);
            }
            catch (Exception ex)
            {
                ExceptionHelper.HandleException(ex);
            }
        }
        #endregion

        #region Private Static Methods
        private static string ReplaceCharacters(string message)
        {
            if (!string.IsNullOrEmpty(message))
            {
                return message.Replace("\\r", "\r").Replace("\\n", "\n");
            }
            return null;
        }
        #endregion
    }

    public class ExceptionHelper
    {
        #region Public Static Methods
        /// <summary>
        /// 
        /// </summary>
        /// <param name="ex"></param>
        public static void HandleException(Exception exception)
        {
            try
            {
                ExceptionPolicy.HandleException(exception, Resources.DefaultExceptionPolicy);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(Resources.DefaultSource, ex.Message, EventLogEntryType.Error);
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="ex"></param>
        /// <param name="exceptionPolicy"></param>
        public static void HandleException(Exception exception, string exceptionPolicy)
        {
            try
            {
                ExceptionPolicy.HandleException(exception, exceptionPolicy);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(Resources.DefaultSource, ex.Message, EventLogEntryType.Error);
            }
        }
        #endregion
    }

}
