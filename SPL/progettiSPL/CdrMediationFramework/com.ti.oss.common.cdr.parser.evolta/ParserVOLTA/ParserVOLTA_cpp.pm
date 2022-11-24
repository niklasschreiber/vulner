
package ParserVOLTA_cpp;
use strict; use Cwd 'realpath';  use File::Basename;  use lib dirname(__FILE__);  use SPL::Operator::Instance::OperatorInstance; use SPL::Operator::Instance::Context; use SPL::Operator::Instance::Expression; use SPL::Operator::Instance::ExpressionTree; use SPL::Operator::Instance::ExpressionTreeVisitor; use SPL::Operator::Instance::ExpressionTreeCppGenVisitor; use SPL::Operator::Instance::InputAttribute; use SPL::Operator::Instance::InputPort; use SPL::Operator::Instance::OutputAttribute; use SPL::Operator::Instance::OutputPort; use SPL::Operator::Instance::Parameter; use SPL::Operator::Instance::StateVariable; use SPL::Operator::Instance::Window; 
sub main::generate($$) {
   my ($xml, $signature) = @_;  
   print "// $$signature\n";
   my $model = SPL::Operator::Instance::OperatorInstance->new($$xml);
   unshift @INC, dirname ($model->getContext()->getOperatorDirectory()) . "/../impl/nl/include";
   $SPL::CodeGenHelper::verboseMode = $model->getContext()->isVerboseModeOn();
   	use Data::Dumper;
   	my $ParserStatisticsName = "ParserStatistics";
   	my $ParserStatisticsPort; # number of statistics port
   
   	my $pduTypes = $model->getParameterByName("pduTypes");
   	my $streamsCount = 0;
   	my %name2Index;
   
   	# determine output port -> pdu mapping
   	my $o=0;
   	#for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   	for(my $o=0; $o < 1; ++$o)
   	{
   		if (!defined($pduTypes->getValueAt($o)))
   		{
   			SPL::CodeGen::exitln("No PDU type defined in parameter \"pduTypes\" for output port: $o");
   		}
   
   		my $pduName = $pduTypes->getValueAt($o)->getSPLExpression();
   		$pduName =~ s/"//g;
   
   		$name2Index{$pduName} = $o;
   #		print STDERR "name2Index: $pduName -> $o \n";
   
   		$ParserStatisticsPort = $o if ($pduName eq $ParserStatisticsName);
   
   		++$streamsCount;
   	}
   	
   #	print STDERR "ParserStatisticsPort: $ParserStatisticsPort\n";
   
   	sub getPduNameByStreamIndex($)
   	{
   		my ($index) = @_;
   
   #		print STDERR "--> getPduNameByStreamIndex(", (defined $index ? $index : "UNDEF"), ")\n";
   
   		my $result;
   		if (defined $index)
   		{
   			my $name;
   			foreach $name(keys%name2Index)
   			{
   				$result = $name if ($index == $name2Index{$name});
   			}			
   		}
   
   #		print STDERR "<-- getPduNameByStreamIndex --> [", (defined $result ? $result : "UNDEF"), "]\n";
   
   		return($result);	
   	}
   
   	sub getStreamIndexByPduName($)
   	{
   		my ($name) = @_;
   
   #		print STDERR "--> getStreamIndexByPduName(", (defined $name ? $name : "UNDEF"), ")\n";
   
   		my $result;
   		if (defined $name)
   		{
   			$result = $name2Index{$name} if (exists $name2Index{$name});
   		}
   
   #		print STDERR "<-- getStreamIndexByPduName --> [", (defined $result ? $result : "UNDEF"), "]\n";
   
   		return($result);
   	}
   	
   	# -------------------------------------------------------------------------
   	# C++ to streams mapping
   	# -------------------------------------------------------------------------
   	my %streams =
   	(
   		"Volta" =>
   		{
   			# SPL                               C++
   			"callModuleType" => "pdu->callModuleType",			
   
   			#listOfCallingPartyAddresses:        
   			"listOfCallingPartyAddresses" => "pdu->listOfCallingPartyAddresses",
   											
   			"callingPartyAddressPresentationStatus"                  => "pdu->callingPartyAddressPresentationStatus",
   			"callingPartyAddressE164"                     => "pdu->callingPartyAddressE164",
   			"callingPartyMSISDN"	                     => "pdu->callingPartyMSISDN",
   			"fromHeader"                  => "pdu->fromHeader",
   			"fromHeaderPresentationStatus"                 => "pdu->fromHeaderPresentationStatus",
   			"callingSubscriberIMPI"                         => "pdu->callingSubscriberIMPI",
   			"callingSubscriberIMSI"                     => "pdu->callingSubscriberIMSI",
   			"calledPartyAddress"            => "pdu->calledPartyAddress",
   			"calledPartyAddressE164"          => "pdu->calledPartyAddressE164",
   			"calledPartyMSISDN"          => "pdu->calledPartyMSISDN",
   
   			"translatedNumber"               => "pdu->translatedNumber",
   			"startTime"        => "pdu->startTime",
   			"chargeableDuration"      => "pdu->chargeableDuration",
   			"callIdentification"             => "pdu->callIdentification",
   			
   			#listOfRelatedCallIdentification:
   			"listOfRelatedCallIdentification"                  => "pdu->listOfRelatedCallIdentification",
   			
   			"partialOutputRecordNumber"           => "pdu->partialOutputRecordNumber",
   			"lastPartialOutput"                    => "pdu->lastPartialOutput",
   			"iMSChargingIdentifier"          => "pdu->iMSChargingIdentifier",
   			"listOfRelatedICID"        => "pdu->listOfRelatedICID",
   			"originatingNetwork"                      => "pdu->originatingNetwork",
   			"terminatingNetwork"                  => "pdu->terminatingNetwork",
   			"callPosition"                => "pdu->callPosition",
   			"causeCode"           => "pdu->causeCode",
   			"accessType"         => "pdu->accessType",
   			
   			"listOfMedia"            => "pdu->listOfMedia",
   			"listOfMedia_listOfMedia"             => "pdu->listOfMedia_listOfMedia",
   			"listOfMedia_timeOfMediaChange"      => "pdu->listOfMedia_timeOfMediaChange",
   			
   			"listOfSupplementaryService_supplementaryServiceIdentity"                    => "pdu->listOfSupplementaryService_supplementaryServiceIdentity",
   			"listOfSupplementaryService_supplementaryServiceAction"           => "pdu->listOfSupplementaryService_supplementaryServiceAction",
   			
   			"firstCallingLocationInformation"         => "pdu->firstCallingLocationInformation",
   			"incompleteCallDataIndicator"            => "pdu->incompleteCallDataIndicator",
   			"conferenceId"              => "pdu->conferenceId",
   			"sRVCCTimeStamp"                    => "pdu->sRVCCTimeStamp",
   			"disconnectingParty"      => "pdu->disconnectingParty",
   			"conferenceTimeStamp"                => "pdu->conferenceTimeStamp",
   			"callingSubscriberIMEI"                => "pdu->callingSubscriberIMEI",
   			"calledSubscriberIMEI"                => "pdu->calledSubscriberIMEI",
   			"destinationRealm"                => "pdu->destinationRealm",
   			"sIPRingingTimestamp"                => "pdu->sIPRingingTimestamp",
   			"freeFormatData"                => "pdu->freeFormatData",
   			"redirectingSubscriberIMPI"                 => "pdu->redirectingSubscriberIMPI",
   			"redirectingSubscriberIMSI"   => "pdu->redirectingSubscriberIMSI",
   			"redirectingPartyAddress"     => "pdu->redirectingPartyAddress",
   			"redirectingPartyAddressE164" => "pdu->redirectingPartyAddressE164",
   			"redirectionCounter"           => "pdu->redirectionCounter",
   			"originalCalledPartyAddress"             => "pdu->originalCalledPartyAddress",
   			"originalCalledPartyAddressE164"               => "pdu->originalCalledPartyAddressE164",
   			"calledSubscriberIMPI"           => "pdu->calledSubscriberIMPI",
   			"calledSubscriberIMSI"  => "pdu->calledSubscriberIMSI",
   			"firstCalledLocationInformation"            => "pdu->firstCalledLocationInformation",
   
   			# listOfServiceData - end
   			"endOfData"					  => "EOD",
   		},
   
   		# ---------------------------------------------------------------------
   		# statistics stream
   		# ---------------------------------------------------------------------
   		"$ParserStatisticsName" =>
   		{
   			"filename"                    => "buffer.getFilename()",
   			"bytesTotal"                  => "buffer.getTotal()",
   			"bytesSkipped"                => "buffer.getSkipped()",
   			"cdrPerSecond"                => "(long) (this->stopWatchProcess.get() > 0.0 ? (double) parser.goodCDR / this->stopWatchProcess.get() : 0.0)",
   			"goodCDR"                     => "parser.goodCDR",
   			"badCDR"                      => "parser.badCDR",
   			"ignoredCDR"                  => "parser.ignoredCDR",
   			"abortedDueToDecodeFailure"   => "parser.abortedDueToDecodeFailure",
   			"timeToParseFile"             => "parser.totalStopWatch.get()",
   			"timeToReadFile"              => "parser.bufferStopWatch.get()",
   			"timeToDecode"                => "parser.decoderStopWatch.get()",
   			"timeToConvert"               => "parser.converterStopWatch.get()",
   			"bytesProcessed"              => "parser.bytesProcessed",
   			"timeToProcessFile"           => "this->stopWatchProcess.get()",
   			"timeToSend"                  => "this->stopWatchSend.get()",
   			"errors"                      => "pdu->errors",
   			# MSC
   			"goodMSC"                     => "pdu->goodMSC",
   			"badMSC"                      => "pdu->badMSC",
   			"timeToConvertMSC"            => "pdu->timeToConvertMSC.get()",
   			"timeToSendMSC"               => "this->stopWatchSendOnPort" . getStreamIndexByPduName("Volta") . ".get()",
   		},
   	);
   
   	my %generics =
   	(
   		"processingStartedAt" => "this->processingStartedAt",
   		"processingStoppedAt" => "this->processingStoppedAt",
   		"EOL" => "\"\"",
   	);
   
   	sub getParserAssignment($$)
   	{
   		my ($pduName,$attrName) = @_;
   
   #		print STDERR "--> getParserAssignment(", (defined $pduName ? $pduName : "UNDEF"), ",", (defined $attrName ? $attrName : "UNDEF"), ")\n";
   
   		# try to get PDU-dependent assignment
   		my $result = $streams{$pduName}{$attrName};
   		if (!defined $result)
   		{
   			# try to get generic assignment
   			$result = $generics{$attrName};
   		}
   
   #		print STDERR "<-- getParserAssignment --> [", (defined $result ? $result : "UNDEF"), "]\n";
   
   		return($result);
   	}
   print "\n";
   print "\n";
   print '/* Additional includes go here */', "\n";
   print "\n";
   print '// ASN.1 parser includes', "\n";
   	foreach my $type (keys %streams)
   	{
   		if ($type eq $ParserStatisticsName)
   		{ 
   print "\n";
   print '//#include "';
   print $type;
   print '.h"', "\n";
   		}
   		else
   		{
   print "\n";
   print '#include "LionetAsn1Cdr';
   print $type;
   print 'Plugin/';
   print $type;
   print 'Pdu.hpp"', "\n";
   print "\n";
   print 'using namespace LionetAsn1Cdr';
   print $type;
   print 'Plugin;', "\n";
   		}
   	}
   print "\n";
   SPL::CodeGen::implementationPrologue($model);
   print "\n";
   print "\n";
   print 'using namespace std;', "\n";
   print "\n";
   print '/**', "\n";
   print ' * The parser statistics are stored in a non-PDU class, but to reuse', "\n";
   print ' * code, we have the mapping between the both names.', "\n";
   print ' */', "\n";
   print '#define ParserStatisticsPDU ParserStatistics', "\n";
   print "\n";
   print '// LOCAL INCLUDE FILES', "\n";
   print '#include <HashedXmlConfigurationFile/HashedXmlConfigFile.hpp>', "\n";
   print "\n";
   print 'using namespace HashedXmlConfigurationFile;', "\n";
   print "\n";
   print '// global includes', "\n";
   print '#include <stdlib.h>', "\n";
   print "\n";
   print "\n";
   print '// Constructor', "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::MY_OPERATOR()', "\n";
   print '{', "\n";
   print '	';
   		my $configEnvVar = $model->getParameterByName("configEnvVar");
   		$configEnvVar = $configEnvVar->getValueAt(0)->getCppExpression();
   
   		my $mediationName = $model->getParameterByName("mediationName");
   		$mediationName = $mediationName->getValueAt(0)->getCppExpression();
   
   		my $configFileKey = $model->getParameterByName("configFileKey");
   		$configFileKey = $configFileKey->getValueAt(0)->getCppExpression();
   	
   print "\n";
   print '	stopWatchProcess.setName("process");', "\n";
   print '	stopWatchSend.setName("send");', "\n";
   print "\n";
   print '	char *envVar;', "\n";
   print '	string medConfigFile;', "\n";
   print '	string configFile;', "\n";
   print "\n";
   print ' 	envVar = getenv(';
   print $configEnvVar;
   print '.c_str());', "\n";
   print ' ', "\n";
   print '	if ( envVar == NULL )', "\n";
   print '	{', "\n";
   print '		SPLAPPTRC(L_ERROR, "Error retrieving environment variable \\"" << ';
   print $configEnvVar;
   print ' << "\\"", "dpsop");', "\n";
   print '	}', "\n";
   print "\n";
   print '	medConfigFile.append(envVar);', "\n";
   print "\n";
   print '	if (medConfigFile.size() == 0)', "\n";
   print '	{', "\n";
   print '		medConfigFile = "/";', "\n";
   print '	}', "\n";
   print "\n";
   print '	if (medConfigFile[medConfigFile.size() - 1] != \'/\')', "\n";
   print '		 medConfigFile += "/";', "\n";
   print "\n";
   print '	medConfigFile += ';
   print $mediationName;
   print ' + "/" + ';
   print $mediationName;
   print ' + ".xml"; ', "\n";
   print "\n";
   print '	if (!HashedXmlConfigFile::getInstance().load(medConfigFile))', "\n";
   print '	{', "\n";
   print '		SPLAPPTRC(L_ERROR, "Error loading mediation configuration file \\"" << medConfigFile << "\\"", "dpsop");', "\n";
   print '	}', "\n";
   print "\n";
   print '	if (!HashedXmlConfigFile::getInstance().getParameter(';
   print $configFileKey;
   print ', configFile))', "\n";
   print '	{', "\n";
   print '		SPLAPPTRC(L_ERROR, "Parser configuration file name with key \\"" << ';
   print $configFileKey;
   print ' << "\\" not found in \\"" << medConfigFile << "\\"", "dpsop");', "\n";
   print '	}', "\n";
   print "\n";
   print '	parserEngine = new Asn1CdrVoltaParserEngine();', "\n";
   print ' ', "\n";
   print '	if (!parserEngine->init(configFile))', "\n";
   print '	{', "\n";
   print '		SPLAPPTRC(L_ERROR, "Error initializing Parser Engine with file \\"" << configFile << "\\"", "dpsop");', "\n";
   print '	}', "\n";
   print '	';
   	
   		my $name;
   		foreach $name(keys%name2Index)
   		{
   			next if ($name eq $ParserStatisticsName);
   	
   print "\n";
   print '	STREAM_TO_PORT.insert(pair<std::string,int>("';
   print $name;
   print '",';
   print $name2Index{$name};
   print '));', "\n";
   print '	';
   		}
   	
   print "\n";
   print '	';
   		#for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   		for(my $o=0; $o < 1; ++$o)
   		{
   	
   print "\n";
   print '	stopWatchSendOnPort';
   print $o;
   print '.setName("sendOnPort';
   print $o;
   print '");', "\n";
   print '	';
   		}
   	
   print '	    ', "\n";
   print '}', "\n";
   print "\n";
   print '// Destructor', "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::~MY_OPERATOR() ', "\n";
   print '{', "\n";
   print '	delete parserEngine;', "\n";
   print '}', "\n";
   print "\n";
   print '// Notify port readiness', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::allPortsReady() ', "\n";
   print '{', "\n";
   print '}', "\n";
   print "\n";
   print '// Notify pending shutdown', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::prepareToShutdown() ', "\n";
   print '{', "\n";
   print '}', "\n";
   print "\n";
   print '// Processing for source and threaded operators   ', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(uint32_t idx)', "\n";
   print '{', "\n";
   print '}', "\n";
   print "\n";
   print '// Tuple processing for mutating ports ', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(Tuple & tuple, uint32_t port)', "\n";
   print '{', "\n";
   print '	IPort0Type const & ituple = static_cast<IPort0Type const&>(tuple);	', "\n";
   print "\n";
   print ' 	// reset statistics, parser, buffer, etc.', "\n";
   print '//	ParserStatistics::initialize();', "\n";
   print "\n";
   print '	// get timestamp', "\n";
   print '	const char* timeStringFormat = "%Y-%m-%d %H:%M:%S";', "\n";
   print '	const int timeStringLength = 20;', "\n";
   print '	char timeString[timeStringLength];', "\n";
   print '	', "\n";
   print '	time_t t = time(0);', "\n";
   print '	tm *curTime = localtime(&t);', "\n";
   print '	strftime(timeString, timeStringLength, timeStringFormat, curTime);	', "\n";
   print "\n";
   print '	processingStartedAt.assign(timeString, timeStringLength);', "\n";
   print "\n";
   print '	// start processing FileHeader', "\n";
   print '	std::string filename(ituple.get_fName());', "\n";
   print "\n";
   print '	stopWatchProcess.reset().start();', "\n";
   print '	stopWatchSend.reset();', "\n";
   print '	';
   		#for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   		for(my $o=0; $o < 1; ++$o)
   		{
   	
   print "\n";
   print '	stopWatchSendOnPort';
   print $o;
   print '.reset();', "\n";
   print '	sentOnPort';
   print $o;
   print ' = 0L;', "\n";
   print '	';
   		}
   	
   print "\n";
   print '	// ASN.1 decoder and converter (to PDU format)', "\n";
   print "\n";
   print '	SPLAPPTRC(L_INFO, "Parsing file \\"" << filename << "\\" with " << parserEngine->getName() << "...", "dpsop");', "\n";
   print '	', "\n";
   print '	if (!parserEngine->start(filename, "50"))', "\n";
   print '	{', "\n";
   print '		SPLAPPTRC(L_ERROR, "Error parsing file \\"" << filename << "\\"", "dpsop");', "\n";
   print '	}', "\n";
   print '	else', "\n";
   print '	{', "\n";
   print '		Pdu *pdu;', "\n";
   print "\n";
   print '		while ((pdu = parserEngine->getNextPdu()) != NULL)', "\n";
   print '		{', "\n";
   print '			stopWatchSend.start();', "\n";
   print "\n";
   print '			StreamToPortIterator_t iterator = STREAM_TO_PORT.find(pdu->getType());', "\n";
   print '			int oport = (STREAM_TO_PORT.end() == iterator ? -1 : iterator->second);', "\n";
   print "\n";
   print '			switch (oport)', "\n";
   print '			{', "\n";
   print '				';
   					#for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   					for(my $o=0; $o < 1; ++$o)
   					{
   						next if (defined($ParserStatisticsPort) && ($o == $ParserStatisticsPort));
   				
   print "\n";
   print '				case ';
   print $o;
   print ':', "\n";
   print '				{', "\n";
   print '					sendPdu(pdu, tuple, port, outputTuple';
   print $o;
   print ');', "\n";
   print "\n";
   print '					break;', "\n";
   print '				}', "\n";
   print '				';
   					}
   				
   print "\n";
   print '				default:', "\n";
   print '				{', "\n";
   print '					SPLAPPTRC(L_ERROR, "Invalid PDU type \\"" << pdu->getType() << "\\"", "dpsop");', "\n";
   print "\n";
   print '					break;', "\n";
   print '				}', "\n";
   print '			}', "\n";
   print "\n";
   print '			pdu->reuse();', "\n";
   print "\n";
   print '			stopWatchSend.stop();', "\n";
   print '		}', "\n";
   print "\n";
   print '		SPLAPPTRC(L_INFO, "File \\"" << filename << "\\" parsed with " << parserEngine->getName(), "dpsop");', "\n";
   print '	}', "\n";
   print '	';
   		#for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   		for(my $o=0; $o < 1; ++$o)
   		{
   			#next if ($o == $ParserStatisticsPort);
   
   			next if (defined($ParserStatisticsPort) && ($o == $ParserStatisticsPort));			
   	
   print "\n";
   print '	if (0 != sentOnPort';
   print $o;
   print ')', "\n";
   print '	{', "\n";
   print '		EOD = true;', "\n";
   print '		', "\n";
   print '		// set FileHeader', "\n";
   print '		outputTuple';
   print $o;
   print '.set_endOfData(EOD);', "\n";
   print '		', "\n";
   print '		submit(outputTuple';
   print $o;
   print ', ';
   print $o;
   print '); // submit to output port ';
   print $o;
   print "\n";
   print '		submit(Punctuation::WindowMarker, ';
   print $o;
   print ');', "\n";
   print '		//Submit the punct on the output port 1', "\n";
   print '		submit(Punctuation::WindowMarker, 1);', "\n";
   print '		', "\n";
   print '	}', "\n";
   print '	';
   		}
   	
   print "\n";
   print '	// get timestamp', "\n";
   print '	t = time(0);', "\n";
   print '	curTime = localtime(&t);', "\n";
   print '	strftime(timeString, timeStringLength, timeStringFormat, curTime);', "\n";
   print "\n";
   print '	processingStoppedAt.assign(timeString, timeStringLength);', "\n";
   print "\n";
   print '	stopWatchProcess.stop();', "\n";
   print '	';
   		if (defined $ParserStatisticsPort)
   		{
   	
   print "\n";
   print '	// send statistics', "\n";
   print '	sendPdu(ParserStatistics::getInstance(), tuple, port, outputTuple';
   print $ParserStatisticsPort;
   print ');', "\n";
   print '	';
   		}
   	
   print "\n";
   print '}', "\n";
   print "\n";
   print '// Tuple processing for non-mutating ports', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(Tuple const & tuple, uint32_t port)', "\n";
   print '{', "\n";
   print '}', "\n";
   print "\n";
   print '// Punctuation processing', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(Punctuation const & punct, uint32_t port)', "\n";
   print '{', "\n";
   print '	submit(punct,port);', "\n";
   print '}', "\n";
   print "\n";
   print '/*', "\n";
   print ' * ----------------------------------------------------------------------------', "\n";
   print ' * sendPdu', "\n";
   print ' * ----------------------------------------------------------------------------', "\n";
   print ' */', "\n";
   	
   	#for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   	for(my $o=0; $o < 1; ++$o)
   	{
   		my $ostream = $model->getOutputPortAt($o);
   		my $pdu = getPduNameByStreamIndex($o);
   		
   		if (!defined $pdu)
   		{
   			SPL::CodeGen::exitln("No PDU name for stream index: $o");
   		}
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::sendPdu(const Pdu* genericPdu, Tuple& tuple, uint32_t port, OPort';
   print $o;
   print 'Type& otuple)', "\n";
   print '{ ', "\n";
   print '	IPort0Type const & ituple = static_cast<IPort0Type const&>(tuple);', "\n";
   print '	';
   		my $istream = $model->getInputPortAt(0);
   	
   print "\n";
   print '	// cast generic PDU to concrete type', "\n";
   print '	const ';
   print $pdu;
   print 'Pdu *pdu = (';
   print $pdu;
   print 'Pdu *) genericPdu;', "\n";
   print "\n";
   print '	// Determine time being used to send the tuple.', "\n";
   print '	stopWatchSendOnPort';
   print $o;
   print '.start();', "\n";
   print "\n";
   print '	// Reset output tuple.', "\n";
   print '	otuple.reset();', "\n";
   print "\n";
   print '	// Iterate through the output tuple attributes. If a output tuple attribute', "\n";
   print '	// has a corresponding PDU attribute, then generate the conversion code,', "\n";
   print '	// else try to get the output tuple attribute value from the input tuple.', "\n";
   print '	';
   		foreach my $attr (@{$ostream->getAttributes()})
   		{
   			my $oname = $attr->getName();
   			my $otype = $attr->getSPLType();
   			my $assignment;
   
   			# -----------------------------------------------------------------
   			# The intention of this commented code snippet is that assignments
   			# within the InfoSphere Streams UBOP take precedence over any
   			# automatic assignment. Unfortunately, this is not working as
   			# expected.
   			# -----------------------------------------------------------------
   			# if ($attr->hasAssignment())
   			#{
   			#	$assignment = $attr->getAssignment();
   			#	print STDERR "    sendPdu: [0] $oname := $assignment", "\n";
   			#	print STDERR Dumper($assignment);
   			#}
   			#else
   			{
   				$assignment = getParserAssignment($pdu, $oname);
   				if (defined $assignment)
   				{
   #					print STDERR "    sendPdu: [1] $oname := $assignment", "\n";
   				}
   				else
   				{
   					$assignment = "ituple.get_$oname()" if (defined $istream->getAttributeByName($oname));
   					if (defined $assignment)
   					{
   #						print STDERR "    sendPdu: [2] $oname := $assignment", "\n";
   					}
   					else
   					{					  
   						SPL::CodeGen::exitln("no assignment rule for " . $pdu . " " . $oname);
   					}
   				}
   			}
   			if ($otype =~ m/(list)/)
   			{
   				my $cppType = $attr->getCppType();
   	
   print "\n";
   print '	{', "\n";
   print '		';
   print $cppType;
   print ' tmp;', "\n";
   print '		tmp.assign(';
   print $assignment;
   print '.begin(), ';
   print $assignment;
   print '.end());', "\n";
   print '		otuple.set_';
   print $oname;
   print ' (tmp);', "\n";
   print '	}', "\n";
   print '	';
   			}
   			else
   			{
   	
   print "\n";
   print '	{', "\n";
   print '		otuple.set_';
   print $oname;
   print ' (';
   print $assignment;
   print ');', "\n";
   print '	}', "\n";
   print '	';
   			}
   		}
   	
   print "\n";
   print '	EOD = false;', "\n";
   print '	', "\n";
   print '	// set FileHeader', "\n";
   print '	otuple.set_eventCorrelationId(ituple.get_eventCorrelationId());', "\n";
   print '	otuple.set_sessionBeginTime(ituple.get_sessionBeginTime());', "\n";
   print '	otuple.set_rop(ituple.get_rop());', "\n";
   print '	otuple.set_fName(ituple.get_fName());', "\n";
   print '	otuple.set_emId(ituple.get_emId());', "\n";
   print '	otuple.set_neId(ituple.get_neId());', "\n";
   print '	otuple.set_endOfData(EOD);', "\n";
   print "\n";
   print '	// Count the number of sent tuples on this port. Needed information to', "\n";
   print '	// decide whether a punctuation needs to be sent on a port.', "\n";
   print '	submit(outputTuple';
   print $o;
   print ', ';
   print $o;
   print '); // submit to output port ';
   print $o;
   print "\n";
   print '	', "\n";
   print '	++sentOnPort';
   print $o;
   print ';', "\n";
   print '	// Determine time being used to send the tuple.', "\n";
   print '	', "\n";
   print '	stopWatchSendOnPort';
   print $o;
   print '.stop();', "\n";
   print '}', "\n";
   	
   	}
   print "\n";
   SPL::CodeGen::implementationEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
