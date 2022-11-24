// AppSettings.cpp : main project file.

#include "stdafx.h"

#include "MySection.h"

using namespace System;
using namespace System::Configuration;
using namespace testAppConfig;

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