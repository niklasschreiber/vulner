void
ziflist_reload (ziflist_t *self)
{
    assert (self);
    zlistx_t *list = (zlistx_t *) self;
    zlistx_purge (list);

#if defined (HAVE_GETIFADDRS)
    struct ifaddrs *interfaces;
    if (getifaddrs (&interfaces) == 0) {
        struct ifaddrs *interface = interfaces;
        while (interface) {
            //  On Solaris, loopback interfaces have a NULL in ifa_broadaddr
            if (  interface->ifa_broadaddr
               && interface->ifa_addr
               && interface->ifa_addr->sa_family == AF_INET
               && s_valid_flags (interface->ifa_flags)) {
                inaddr_t address = *(inaddr_t *) interface->ifa_addr;
                inaddr_t netmask = *(inaddr_t *) interface->ifa_netmask;
                inaddr_t broadcast = *(inaddr_t *) interface->ifa_broadaddr;

                //  If the returned broadcast address is the same as source
                //  address, build the broadcast address from the source
                //  address and netmask.
                if (address.sin_addr.s_addr == broadcast.sin_addr.s_addr)
                    broadcast.sin_addr.s_addr |= ~(netmask.sin_addr.s_addr);

                interface_t *item =
                    s_interface_new (interface->ifa_name, address, netmask,
                                     broadcast);
                if (item)
                    zlistx_add_end (list, item);
            }
            interface = interface->ifa_next;
        }
    }
    freeifaddrs (interfaces);

#   elif defined (__UNIX__)
    int sock = socket (AF_INET, SOCK_DGRAM, 0);
    if (sock != -1) {
        int num_interfaces = 0;
        struct ifconf ifconfig = { 0 };
        //  First ioctl call gets us length of buffer; second call gets us contents
        if (!ioctl (sock, SIOCGIFCONF, (caddr_t) &ifconfig, sizeof (struct ifconf))) {
            ifconfig.ifc_buf = (char *) zmalloc (ifconfig.ifc_len);
            if (!ioctl (sock, SIOCGIFCONF, (caddr_t) &ifconfig, sizeof (struct ifconf)))
                num_interfaces = ifconfig.ifc_len / sizeof (struct ifreq);
        }
        int index;
        for (index = 0; index < num_interfaces; index++) {
            struct ifreq *ifr = &ifconfig.ifc_req [index];
            //  Check interface flags
            bool is_valid = false;
            if (!ioctl (sock, SIOCGIFFLAGS, (caddr_t) ifr, sizeof (struct ifreq)))
                is_valid = s_valid_flags (ifr->ifr_flags);

            //  Get interface properties
            inaddr_t address = { 0 };
            if (!ioctl (sock, SIOCGIFADDR, (caddr_t) ifr, sizeof (struct ifreq)))
                address = *((inaddr_t *) &ifr->ifr_addr);
            else
                is_valid = false;

            inaddr_t broadcast = { 0 };
            if (!ioctl (sock, SIOCGIFBRDADDR, (caddr_t) ifr, sizeof (struct ifreq)))
                broadcast = *((inaddr_t *) &ifr->ifr_addr);
            else
                is_valid = false;

            inaddr_t netmask = { 0 };
            if (!ioctl (sock, SIOCGIFNETMASK, (caddr_t) ifr, sizeof (struct ifreq)))
                netmask = *((inaddr_t *) &ifr->ifr_addr);
            else
                is_valid = false;

            if (is_valid) {
                interface_t *item = s_interface_new (ifr->ifr_name, address,
                                                     netmask, broadcast);
                if (item)
                    zlistx_add_end (list, item);
            }
        }
        free (ifconfig.ifc_buf);
        close (sock);
    }

#   elif defined (__WINDOWS__)
    ULONG addr_size = 0;
    DWORD rc = GetAdaptersAddresses (AF_INET, GAA_FLAG_INCLUDE_PREFIX, NULL, NULL, &addr_size);
    assert (rc == ERROR_BUFFER_OVERFLOW);

    PIP_ADAPTER_ADDRESSES pip_addresses = (PIP_ADAPTER_ADDRESSES) zmalloc (addr_size);
    rc = GetAdaptersAddresses (AF_INET,
                               GAA_FLAG_INCLUDE_PREFIX, NULL, pip_addresses, &addr_size);
    assert (rc == NO_ERROR);

    PIP_ADAPTER_ADDRESSES cur_address = pip_addresses;
    while (cur_address) {
        PIP_ADAPTER_UNICAST_ADDRESS pUnicast = cur_address->FirstUnicastAddress;
        PIP_ADAPTER_PREFIX pPrefix = cur_address->FirstPrefix;

        PWCHAR friendlyName = cur_address->FriendlyName;
        size_t asciiSize = wcstombs (0, friendlyName, 0) + 1;
        char *asciiFriendlyName = (char *) zmalloc (asciiSize);
        wcstombs (asciiFriendlyName, friendlyName, asciiSize);

        bool valid = (cur_address->OperStatus == IfOperStatusUp)
                     && (pUnicast && pPrefix)
                     && (pUnicast->Address.lpSockaddr->sa_family == AF_INET)
                     && (pPrefix->PrefixLength <= 32);

        if (valid) {
            inaddr_t address = *(inaddr_t *) pUnicast->Address.lpSockaddr;
            inaddr_t netmask;
            netmask.sin_addr.s_addr = htonl ((0xffffffffU) << (32 - pPrefix->PrefixLength));
            inaddr_t broadcast = address;
            broadcast.sin_addr.s_addr |= ~(netmask.sin_addr.s_addr);
            interface_t *item = s_interface_new (asciiFriendlyName, address,
                                                 netmask, broadcast);
            if (item)
                zlistx_add_end (list, item);
        }
        free (asciiFriendlyName);
        cur_address = cur_address->Next;
    }
    free (pip_addresses);

#   else
#       error "Interface detection TBD on this operating system"
#   endif
}