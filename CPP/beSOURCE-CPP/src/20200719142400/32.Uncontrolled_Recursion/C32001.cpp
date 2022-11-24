/**
* 
* 
* 
* 
*
* 
* 
*
*
* 
* 
*   
*
*/

int recursive_func(n) {
	int ret=0;
	
	if(ret=n*recursive_func(n-1)<0) { ret = -1; }
	else { ret=1; }
	

    return ret;
}
