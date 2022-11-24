
package ParserVOLTA_h;
use strict; use Cwd 'realpath';  use File::Basename;  use lib dirname(__FILE__);  use SPL::Operator::Instance::OperatorInstance; use SPL::Operator::Instance::Context; use SPL::Operator::Instance::Expression; use SPL::Operator::Instance::ExpressionTree; use SPL::Operator::Instance::ExpressionTreeVisitor; use SPL::Operator::Instance::ExpressionTreeCppGenVisitor; use SPL::Operator::Instance::InputAttribute; use SPL::Operator::Instance::InputPort; use SPL::Operator::Instance::OutputAttribute; use SPL::Operator::Instance::OutputPort; use SPL::Operator::Instance::Parameter; use SPL::Operator::Instance::StateVariable; use SPL::Operator::Instance::Window; 
sub main::generate($$) {
   my ($xml, $signature) = @_;  
   print "// $$signature\n";
   my $model = SPL::Operator::Instance::OperatorInstance->new($$xml);
   unshift @INC, dirname ($model->getContext()->getOperatorDirectory()) . "/../impl/nl/include";
   $SPL::CodeGenHelper::verboseMode = $model->getContext()->isVerboseModeOn();
   print '/* Additional includes go here */', "\n";
   print "\n";
   print '// ASN.1 parser includes', "\n";
   print '#include <Asn1CdrVoltaEngine/Asn1CdrVoltaParserEngine.hpp>', "\n";
   print '#include <ParserEngine/Pdu.hpp>', "\n";
   print '#include <ConvUtils/StopWatch.hpp>', "\n";
   print "\n";
   print 'using namespace Asn1CdrVoltaEngine;', "\n";
   print 'using namespace ParserEngine;', "\n";
   print "\n";
   SPL::CodeGen::headerPrologue($model);
   print "\n";
   print "\n";
   print 'class MY_OPERATOR : public MY_BASE_OPERATOR ', "\n";
   print '{', "\n";
   print 'public:', "\n";
   print '	MY_OPERATOR();', "\n";
   print '	virtual ~MY_OPERATOR(); ', "\n";
   print '	void allPortsReady(); ', "\n";
   print '	void prepareToShutdown(); ', "\n";
   print '	void process(uint32_t idx);', "\n";
   print '	void process(Tuple & tuple, uint32_t port);', "\n";
   print '	void process(Tuple const & tuple, uint32_t port);', "\n";
   print '	void process(Punctuation const & punct, uint32_t port);', "\n";
   print "\n";
   print 'private:', "\n";
   print '	/*', "\n";
   print '	 * The map contains all Stream names and their corresponding', "\n";
   print '	 * port number.', "\n";
   print '	 */', "\n";
   print '	typedef std::map<std::string,int> StreamToPort_t;', "\n";
   print '	typedef StreamToPort_t::iterator StreamToPortIterator_t;', "\n";
   print '	StreamToPort_t STREAM_TO_PORT;', "\n";
   print "\n";
   print '	/*', "\n";
   print '	 * The method copies the PDU content to the output tuple. If any', "\n";
   print '	 * output tuple attribute has no corresponding field in the PDU,', "\n";
   print '	 * then the input tuple is checked for the same.', "\n";
   print '	 * As a result, input tuple attributes can be easily passed to the', "\n";
   print '	 * output tuple.', "\n";
   print '	 */', "\n";
   print '	';
    #for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   	for(my $o=0; $o < 1; ++$o)
   	{
   	
   print "\n";
   print '	void sendPdu(const Pdu* pdu, Tuple& tuple, uint32_t port, OPort';
   print $o;
   print 'Type& otuple);', "\n";
   print '	';
   	}
   	
   print "\n";
   print '	/*', "\n";
   print '	 * For each output port a corresponding output tuple and a stop', "\n";
   print '	 * watch are available.', "\n";
   print '	 */', "\n";
   print '	';
    for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   	{
   	
   print "\n";
   print '	OPort';
   print $o;
   print 'Type outputTuple';
   print $o;
   print ';', "\n";
   print '	';
   	}
   	
   print "\n";
   print '	', "\n";
   print '	';
    #for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   	for(my $o=0; $o < 1; ++$o)
   	{
   	
   print "\n";
   print '	StopWatch stopWatchSendOnPort';
   print $o;
   print ';', "\n";
   print '	';
   	}
   	
   print "\n";
   print '	/*', "\n";
   print '	 * The method sendPdu counts for each port the number of sent', "\n";
   print '	 * tuples. This information is needed to generate the final', "\n";
   print '	 * punctuation on the ports, on which tuples were sent.', "\n";
   print '	 */', "\n";
   print '	';
    #for(my $o=0; $o < $model->getNumberOfOutputPorts(); ++$o)
   	for(my $o=0; $o < 1; ++$o)
   	{
   	
   print "\n";
   print '	long sentOnPort';
   print $o;
   print ';', "\n";
   print '	';
   	}
   	
   print "\n";
   print '	/**', "\n";
   print '	 * Stop watch to determine time being spent to completely process', "\n";
   print '	 * the ASN.1 file.', "\n";
   print '	 */', "\n";
   print '	StopWatch stopWatchProcess;', "\n";
   print "\n";
   print '	/**', "\n";
   print '	 * Stop watch to determine time being spent to send PDU.', "\n";
   print '	 */', "\n";
   print '	StopWatch stopWatchSend;', "\n";
   print "\n";
   print '	/*', "\n";
   print '	 * The parser is reponsible to read a file (using the class', "\n";
   print '	 * Buffer), to decode the ASN.1 data and to convert the data', "\n";
   print '	 * into Streams format.', "\n";
   print '	 */', "\n";
   print '	Asn1CdrVoltaParserEngine *parserEngine;', "\n";
   print "\n";
   print '	/**', "\n";
   print '	 * The timestamp, which indicates the start of the processing.', "\n";
   print '	 */', "\n";
   print '	std::string processingStartedAt;', "\n";
   print "\n";
   print '	/**', "\n";
   print '	 * The timestamp, which indicates the end of the processing.', "\n";
   print '	 */', "\n";
   print '	std::string processingStoppedAt;  ', "\n";
   print '	', "\n";
   print '	bool EOD;', "\n";
   print '}; ', "\n";
   print "\n";
   SPL::CodeGen::headerEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
