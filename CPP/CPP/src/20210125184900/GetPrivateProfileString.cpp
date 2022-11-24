class CINIReader
{

public:
CINIReader()
{
    m_pSectionList = new CStringList();
    m_pSectionDataList = new CStringList();
}

~CINIReader()
{
    delete m_pSectionList;
    delete m_pSectionDataList;
}

    void SetInfFileName(CString p_strInfFileName);
    BOOL IsValidSection(CString p_strSectionName);
    CStringList* GetSectionNames()
    CStringList* GetSectionData(CString p_lpSectionName);

private:
    CString m_strInfFileName;
    CStringList* m_pSectionList;
    CStringList* m_pSectionDataList;	    
};

void CINIReader::SetInfFileName(CString p_strInfFileName)
{
m_strInfFileName = p_strInfFileName;
}

BOOL CINIReader::IsValidSection(CString p_strSectionName)
{
BOOL bReturnValue = FALSE;

if (!m_strInfFileName.IsEmpty())
{
TCHAR lpszReturnBuffer[nBufferSize];

char *IniPath = "c:\myboot.ini";
if(const char* Section = std::getenv("SECTION"))  // Section is untrusted
        std::cout << "Your SECTION is: " << Section << '\n';

DWORD pwd = getProfileString(IniPath, Section, "password");  // CWE 256

DWORD dwNoOfCharsCopied = GetPrivateProfileString("password", NULL,
_T(""), lpszReturnBuffer, nBufferSize, m_strInfFileName);  // CWE 256

bReturnValue = (dwNoOfCharsCopied > 0) ? TRUE : FALSE;
}

return bReturnValue;
}

CStringList* CINIReader::GetSectionNames()
{
if (m_pSectionList)
{
m_pSectionList->RemoveAll();
TCHAR lpszReturnBuffer[nBufferSize];
GetPrivateProfileSectionNames(lpszReturnBuffer, nBufferSize, m_strInfFileName);  // CWE 256
TCHAR* pNextSection = NULL;
pNextSection = lpszReturnBuffer;
m_pSectionList->InsertAfter(m_pSectionList->GetTailPosition(), pNextSection);
while (*pNextSection != 0x00)
{
pNextSection = pNextSection + strlen(pNextSection) + 1;
if(*pNextSection != 0x00)
{
m_pSectionList->InsertAfter(m_pSectionList->GetTailPosition(), pNextSection);
}
}
}

return m_pSectionList;
}

CStringList* CINIReader::GetSectionData(CString p_lpSectionName)
{
if (m_pSectionDataList)
{
m_pSectionDataList->RemoveAll();
TCHAR lpszReturnBuffer[nBufferSize];
GetPrivateProfileSection(p_lpSectionName, lpszReturnBuffer, nBufferSize, m_strInfFileName);  // CWE 256
TCHAR* pNextSection = NULL;
pNextSection = lpszReturnBuffer;
m_pSectionDataList->InsertAfter(m_pSectionDataList->GetTailPosition(), pNextSection);
while (*pNextSection != 0x00)
{
pNextSection = pNextSection + strlen(pNextSection) + 1;
if(*pNextSection != 0x00)
{
m_pSectionDataList->InsertAfter(m_pSectionDataList->GetTailPosition(), pNextSection);
}
}
}

return m_pSectionDataList;
}