/**
What is wrong with this code? The problem is the socket needs data to read or not this code will not work. This affects CPU power consumption. Even if there is nothing to do, the code will periodically wake up the CPU, which consumes power
**/
while(true)
{
        // Read data
        result = recv(serverSocket, buffer, bufferLen, 0);

        // Handle data  
        if(result != 0)
        {
                HandleData(buffer);
        }

        // Sleep and repeat
        Sleep(1000);
}
/**
This code will "sleep" if there is nothing to do. No data in the socket - no activity.
**/
WSANETWORKEVENTS NetworkEvents;
WSAEVENT wsaSocketEvent;
wsaSocketEvent = WSACreateEvent();
WSAEventSelect(serverSocket, 
wsaSocketEvent, FD_READ|FD_CLOSE);
while(true)
{
    // Wait until data will be available in 
    the socket
    WaitForSingleObject(wsaSocketEve
    nt, INFINITE);
    // Read data
    result = recv(serverSocket, buffer, 
    bufferLen, 0);
    // Handle data 
    if(result != 0)
    {
        HandleData(buffer);
    }
} 