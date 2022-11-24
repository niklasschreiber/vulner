using System;
using System.Collections.Generic;
using System.Collections;
using System.Text;
using System.IO;

namespace BPLG.Validation
{
    public class FileFormat
    {
        private string m_strFormatSequence;
        private StreamReader m_sr;
        private string m_strCurrentLine;
        private Int32 m_intCurrentLine;
        private Hashtable m_htRows;
        private bool m_bolEndOfFile;

        public string CurrentLine
        {
            get
            {
                return m_strCurrentLine;
            }
        }

        private bool GoToNextLine()
        {
            //apre la riga successiva da analizzare dallo stream
            if (m_sr.EndOfStream)
            {
                m_bolEndOfFile = true;
                return false;
            }
            m_strCurrentLine = m_sr.ReadLine();
            m_intCurrentLine++;
            return true;
        }

        public FileFormat(string strFormatSequence, Hashtable htRows)
        {
            m_strFormatSequence = strFormatSequence;
            m_htRows = htRows;
        }

        public bool Validate(string strFileName)
        {
            m_bolEndOfFile = false;
            m_sr = new StreamReader(strFileName);
            m_intCurrentLine = 0;
            this.GoToNextLine();
            bool bolResul = CheckSequence(m_strFormatSequence);
            return (bolResul && m_bolEndOfFile);
        }

        private bool CheckSequence(string strSequence)
        {
            Int32 intPosition = 0;
            bool bolOkRow;
            while (intPosition < strSequence.Length)
            {
                Int32 intClose;
                switch (strSequence.Substring(intPosition, 1))
                {
                    case "{":
                        intClose = this.GetClosePosition(strSequence, intPosition, "{", "}");
                        bolOkRow = true;
                        while (bolOkRow && (!m_bolEndOfFile))
                        {
                            bolOkRow = CheckSequence(strSequence.Substring(intPosition + 1, intClose - intPosition - 1));
                        }
                        intPosition = intClose + 1;
                        break;
                    case "[":
                        intClose = this.GetClosePosition(strSequence, intPosition, "[", "]");
                        bolOkRow = CheckSequence(strSequence.Substring(intPosition + 1, intClose - intPosition - 1));
                        intPosition = intClose + 1;
                        break;
                    default:
                        bolOkRow = ((RowFormat)m_htRows[strSequence.Substring(intPosition, 3)]).Validate(this.CurrentLine);
                        if (!bolOkRow)
                        {
                            return false;
                        }
                        else
                        {
                            intPosition += 3;
                            this.GoToNextLine();
                        }
                        break;
                }
            }
            return true;

        }

        private Int32 GetClosePosition(string strSequence, Int32 intStartPos, string strStartChar, string strStopChar)
        {
            Int32 intOpened = 1; //Indica il numero di parentesi aperte
            while (intOpened > 0) //Ciclo finchè non sono riuscito a chiudere tutte le parentesi
            {
                intStartPos++;
                Int32 intOpen = strSequence.IndexOf(strStartChar, intStartPos);
                Int32 intClose = strSequence.IndexOf(strStopChar, intStartPos);
                if ((intClose < intOpen) || intOpen == -1)
                {
                    intStartPos = intClose;
                    intOpened--;
                }
                else
                {
                    intStartPos = intOpen;
                    intOpened++;
                }
            }
            return intStartPos;
        }

    }
}
