test:
	date
all:	schema val
xall:	schema val html

val:	val-exa val-odd
val-exa:
	$j ../schema/tei_clarin.rng ../tei_clarin_example.xml
val-odd:
	$j tei_odds.rng ../tei_clarin_schema.xml

# Have to have local source of p5subset, as my Java is too old to fetch it with https!
PARAMS = --localsource=p5subset.xml ../tei_clarin_schema.xml
schema:	val-odd
	Stylesheets/bin/teitorelaxng    ${PARAMS} ../schema/tei_clarin.rng
	Stylesheets/bin/teitornc        ${PARAMS} ../schema/tei_clarin.rnc
	Stylesheets/bin/teitodtd        ${PARAMS} ../schema/tei_clarin.dtd
	Stylesheets/bin/teitoxsd        ${PARAMS} ../schema/tei_clarin.xsd
	Stylesheets/bin/teitoschematron ${PARAMS} ../schema/tei_clarin.sch
	rm ../schema/*.tmp
	rm ../schema/tei_clarin.xsd

#This still needs to be implemented!
#html:	val-odd
#	Stylesheets/bin/teitohtml --profiledir=${CURDIR} --profile=profile --odd ${PARAMS} ../docs/index.html

j = java -jar /usr/local/bin/jing.jar
#s = java -jar ~/bin/saxon9he.jar
#s = java -jar /usr/local/bin/saxon9he.jar
s = java -Djavax.xml.parsers.DocumentBuilderFactory=org.apache.xerces.jaxp.DocumentBuilderFactoryImpl -Djavax.xml.parsers.SAXParserFactory=org.apache.xerces.jaxp.SAXParserFactoryImpl net.sf.saxon.Transform
