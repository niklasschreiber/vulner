#include <iostream>
#include <vector>

using namespace std;

int main(void) {
   vector<int> v;
   char j[4];
   j = gets(); // j is untrusted
   /* Insert 5 elements */
   for (int i = 0; i < 5; ++i)
      v.push_back(i + 1 + atol(j));  // CWE 15

   for (int i = 0; i < v.size(); ++i)
      cout << v[i] << endl;

   return 0;
}