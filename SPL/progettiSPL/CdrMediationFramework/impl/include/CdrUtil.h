#ifndef CDR_UTIL_H_
#define CDR_UTIL_H_

// GLOBAL INCLUDE FILES
    #include <errno.h>
    #include <stdio.h>
    #include <string>
	#include <iostream>
	#include <map>
	#include <Misc/Util.hpp>
    #include <time.h>
    #include <math.h>
    #include <sys/time.h>

using namespace std;

namespace com { namespace ti { namespace oss { namespace common { namespace cdr {  namespace util {

	static SPL::rstring transformUserLocationInfo( SPL::rstring ulc )
	{
		return Util::transformUserLocationInfo( ulc );
	}


	static SPL::int32 cancFile( SPL::rstring filename )
	{
		return remove(filename.c_str());
	}

}	}	}	}	}	}
#endif /* FUNCTIONS_H_ */
