// AppSettings.cpp : main project file.

#include "stdafx.h"
#include "MySection.h"
#import "foo.h" /* VIOLAZ */
#include_next "foo.h" /* VIOLAZ */
#pragma warning (disable: TheWarning)
#include problem_code.h
#pragma warning (default: TheWarning) /* VIOLAZ */
#include <chrono>
#include <mutex>
#include <thread>
#include <iostream> // std::cout

using namespace System;
using namespace System::Configuration;
using namespace testAppConfig;
using namespace std;

using namespace std;
void draw(unique_ptr<Shape> const &shape); //VIOLAZ
void drawAll(vector<unique_ptr<Shape>> v)    //OK
{
  for (auto &shape : v) {
      if (shape) {
        draw(shape);
      }
  }
}



class Transaction {
  ~Transaction() {
    if (!std::uncaught_exception()) { // VIOLAZ
      // commit
    } else {
		
      // rollback
    }
  }
};



std::chrono::milliseconds interval(100);
std::mutex mutex;
int job_shared = 0; // both threads can modify 'job_shared',
int job_exclusive = 0; // only one thread can modify 'job_exclusive'

pthread_mutex_t mtx1,mtx2;

template <typename N, class = typename
  std::enable_if<std::is_integral_v<N> && std::is_signed_v<N>>::type> // VIOLAZ
auto negate(N n) { return -n; }


constexpr double power(double b, int x) {
  if constexpr (std::is_constant_evaluated()) {  // VIOLAZ
    // compile-time implementation
  } else {
      static_assert(std:: is_constant_evaluated(), // VIOLAZ
                  "Swap requires copying");
	string path = "/var/tmp";
     // runtime implementation
  }
}
consteval unsigned combination(unsigned m, unsigned n) {
  if constexpr (std::is_constant_evaluated()) {  // VIOLAZ
    // compile-time implementation
	User * volatile vpUser; // VIOLAZ; pointer is volatile
	User volatile * pvUser;  // OK; User instance is volatile, not the pointer

  }
  return factorial(n) / factorial(m) / factorial(n - m);
} 


void f() throw(); // VIOLAZ
void g() throw(std::exception); // VIOLAZ


void f(char *c);
void g(int i);
void h()
{
    f(NULL); // VIOLAZ
    f(nullptr); // OK    
    g(NULL); // VIOLAZ
	
	if (likely(!v.empty())) { // VIOLAZ
		std::cout <<v[0] <<'\n';
	}
	
	if (unlikely(nullptr == ptr)) { // VIOLAZ
		std::cerr <<"Unexpected null pointer\n";
		exit(0);
	}
	
	if (!v.empty()) [[likely]] { //OK
		std::cout <<v[0] <<'\n';
	}
	
	if (nullptr == ptr) [[unlikely]] {
		exit(0);
	}

}


void job_2() 
{
    mutex.lock(); //VIOLAZ
    std::this_thread::sleep_for(5 * interval);
    ++job_shared;
    mutex.unlock(); //VIOLAZ
}

void job_1() 
{
    std::this_thread::sleep_for(interval); 
    while (true) {
         if (mutex.try_lock()) {  //VIOLAZ
            std::cout << "job shared (" << job_shared << ")\n";
            mutex.unlock(); //VIOLAZ
            return;
        } else {
            ++job_exclusive;
            std::cout << "job exclusive (" << job_exclusive << ")\n";
            std::this_thread::sleep_for(interval);
        }
    }
}



class AirPlaneBad
{
public:
  void* operator new(size_t size);  // VIOLAZ
  void fly();
};

class AirPlaneGood
{
public:
  void* operator new(size_t size);
  void operator delete(void* deadObject, size_t size); //OK
  void fly();
};

class X {};
class Y : virtual X {};
void test() {
  long l;
  auto a = reinterpret_cast<double&>(l); // VIOLAZ: undefined behavior
  Y* y;
  auto x = reinterpret_cast<X*>(y); // VIOLAZ
}

#ifndef _MY_FILE
#define _MY_FILE   // VIOLAZ: starts with '_'

#define FIELD__VAL(field) ##field // VIOLAZ: contains "__"

int free(void *pArg, int len) {  // VIOLAZ: free is a standard function
  int __i; // VIOLAZ: starts with "__"
  char16_t ct;
  //...
}
#endif

void draw(auto_ptr<Shape> p) { cout << s->x() << ", " << s.y() << endl;} // Noncompliant
void f()
{
    std::auto_ptr<Shape> s = createShape(); // VIOLAZ
    draw(s); // This call invalidates s
    draw(s); // This call will crash, because s is null
}


void f1(std::mutex &m) {
  std::scoped_lock lock; // VIOLAZ
  // Do some work
}
void f1(std::mutex &m) {
  std::scoped_lock lock {m}; // OK
  // Do some work
}


void fn ( void ) // VIOLAZ, asm mixed with C/C++ statements
{
  DoSomething ( );
  asm ( "NOP" ); 
  DoSomething ( );
}
void DoCheck(uint32_t dwSomeValue) // OK, solo asm, dichiarative e assert
{
   uint32_t dwRes;

   asm ("bsfl %1,%0"
     : "=r" (dwRes)
     : "r" (dwSomeValue)
     : "cc");  

   assert(dwRes > 3);
}

[[deprecated]] // VIOLAZ
void fun();

// GNU attribute
__attribute__((deprecated)) // VIOLAZ
void fun();

// Microsoft attribute
__declspec(deprecated) // VIOLAZ
void fun();


void f(A<int32_t> * a<:10:>) {   /* VIOLAZ - usage of '<:' instead of '[' and ':>' instead of ']' */
<%                             		 /* VIOLAZ - usage of '<%' instead of '{' */
  a<:0:>->f2<20>();             	/* VIOLAZ - usage of '<:' and ':>' */
%>                              		/* VIOLAZ - usage of '%>' instead of '}' */

}
[[noreturn]] void f () {
  while (1) {
    // ...
    if (/* something*/) {
      return; /* VIOLAZ */
    }
  }
}

    Botan::Cipher_Mode::create("Blowfish/CBC/PKCS7", Botan::ENCRYPTION);      // VIOLAZ: Blowfish use a 64-bit block size makes it vulnerable to birthday attacks
	Botan::Cipher_Mode::create("DES/CBC/PKCS7", Botan::ENCRYPTION);           // VIOLAZ: DES works with 56-bit keys allow attacks via exhaustive search
	Botan::Cipher_Mode::create("3DES/CBC/PKCS7", Botan::ENCRYPTION);          // VIOLAZ: Triple DES is vulnerable to meet-in-the-middle attack
	Botan::Cipher_Mode::create("DESX/CBC/PKCS7", Botan::ENCRYPTION);          // VIOLAZ: Triple DES is vulnerable to meet-in-the-middle attack
	Botan::Cipher_Mode::create("CAST-128/CBC/PKCS7", Botan::ENCRYPTION);      // VIOLAZ: 64-bit size block cipher
	Botan::Cipher_Mode::create("GOST-28147-89/CBC/PKCS7", Botan::ENCRYPTION); // VIOLAZ: 64-bit size block cipher
	Botan::Cipher_Mode::create("IDEA/CBC/PKCS7", Botan::ENCRYPTION);          // VIOLAZ: 64-bit size block cipher
	Botan::Cipher_Mode::create("KASUMI/CBC/PKCS7", Botan::ENCRYPTION);        // VIOLAZ: 64-bit size block cipher
	Botan::Cipher_Mode::create("MISTY1/CBC/PKCS7", Botan::ENCRYPTION);        // VIOLAZ: 64-bit size block cipher
	Botan::Cipher_Mode::create("XTEA/CBC/PKCS7", Botan::ENCRYPTION);          // VIOLAZ: 64-bit size block cipher
	Botan::Cipher_Mode::create("RC4", Botan::ENCRYPTION);                     // VIOLAZ: has numerous design flaws which make it hard to use correctly
	CryptoPP::ARC4::Encryption(key, sizeof(key)); // VIOLAZ: RC4/ARC4 has numerous design flaws which make it hard to use correctly
	CryptoPP::Blowfish::Encryption(key, sizeof(key)); // VIOLAZ: 64-bit size block
	CryptoPP::GOST::Encryption(key, sizeof(key)); // VIOLAZ: 64-bit size block
	CryptoPP::IDEA::Encryption(key, sizeof(key)); // VIOLAZ: 64-bit size block
	CryptoPP::XTEA::Encryption(key, sizeof(key)); // VIOLAZ: 64-bit size block
	CryptoPP::DES::Encryption(key, sizeof(key)); // VIOLAZ: DES works with 56-bit keys allow attacks via exhaustive search
	CryptoPP::DES_EDE2::Encryption(key, sizeof(key)); // VIOLAZ: Triple DES is vulnerable to meet-in-the-middle attack
	CryptoPP::DES_EDE3::Encryption(key, sizeof(key)); // VIOLAZ: Triple DES is vulnerable to meet-in-the-middle attack
	CryptoPP::DES_XEX3::Encryption(key, sizeof(key)); // VIOLAZ: Triple DES is vulnerable to meet-in-the-middle attack
	CryptoPP::RC2::Encryption(key, sizeof(key)); // VIOLAZ: RC2 is vulnerable to a related-key attack
	CryptoPP::RC2Encryption(key, sizeof(key)); // VIOLAZ; alternative
	CryptoPP::RC2Decryption(key, sizeof(key)); // VIOLAZ; alternative
	EVP_bf_cbc(); // VIOLAZ: 64-bit size block
	EVP_cast5_cbc(); // VIOLAZ: 64-bit size block
	EVP_des_cbc(); // VIOLAZ: DES works with 56-bit keys allow attacks via exhaustive search
	EVP_idea_cbc(); // VIOLAZ: 64-bit size block
	EVP_rc4(); // VIOLAZ:  has numerous design flaws which make it hard to use correctly
	EVP_rc2_cbc(); // VIOLAZ: RC2 is vulnerable to a related-key attack


int f(char *tempData) {
  char *path = tmpnam(NULL); /* VIOLAZ */
  FILE* f = fopen(tmpnam, "w");
  fputs(tempData, f);
  fclose(f);
}


void bad1(void)
{
  pthread_mutex_init(&mtx1);
  pthread_mutex_init(&mtx1); /* VIOLAZ */
 

}

void bad2(void)
{
  pthread_mutex_init(&mtx1);
  pthread_mutex_lock(&mtx1);
  pthread_mutex_destroy(&mtx1); /* VIOLAZ manca la unlock */
}

void bad3(void)
{
  pthread_mutex_init(&mtx1);
  pthread_mutex_destroy(&mtx1);
  pthread_mutex_destroy(&mtx1); /* VIOLAZ */
}

void bad4(void)
{
  pthread_mutex_init(&mtx1);
  pthread_mutex_destroy(&mtx1);
  pthread_mutex_lock(&mtx1); /* VIOLAZ già fatta la destroy*/
}

void bad5(void)
{
  pthread_mutex_init(&mtx1);
  pthread_mutex_destroy(&mtx1);
  pthread_mutex_unlock(&mtx1); /* VIOLAZ già fatta la destroy*/
}

void bad(void) {
  pthread_mutex_lock(&mtx1);
  pthread_mutex_lock(&mtx2);
  pthread_mutex_unlock(&mtx1); /* VIOLAZ deve essere prima fatta la unlock di &mtx2 */
  pthread_mutex_unlock(&mtx2);
}

void good(void) {
  pthread_mutex_lock(&mtx1);
  pthread_mutex_lock(&mtx2);
  pthread_mutex_unlock(&mtx2); /* OK */
  pthread_mutex_unlock(&mtx1);
}

int main(array<System::String ^> ^args)
{
  MySection ^ section = (MySection^)ConfigurationManager::GetSection("MySection");
  ListElement^ element1 = section["nico"];
  Console::WriteLine("{0} ; {1}", element1->Name, element1->FirstName);

  ListElement^ element2 = section["CLI"];
  Console::WriteLine("{0} ; {1}", element2->Name, element2->FirstName);

  ConnStr = Configuration::ConfigurationSettings::
                         AppSettings->get_Item("password");    // CWE 256
  return 0;
}

void f(char *password, size_t bufferSize) {
  char localToken[256];
  init(localToken, password);
  memset(password, ' ', strlen(password)); // VIOLAZ più avanti (nello stesso metodo) c’è la free di password
  memset(localToken, ' ', strlen(localToken)); 
  free(password);
}




