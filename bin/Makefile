test:
	date
all:	schema val
xall:	schema val docs

val:	val-exa val-odd
val-exa:
	$j ../schema/tei_clarin.rng ../tei_clarin_example.xml
val-odd:
	$j tei_odds.rng ../tei_clarin_schema.xml

#PARAMS = --localsource=https://tei-c.org/release/xml/tei/odd/p5subset.xml ../tei_clarin_schema.xml
PARAMS = --localsource=p5subset.xml ../tei_clarin_schema.xml

schema:	val-odd
	Stylesheets/bin/teitorelaxng    ${PARAMS} ../schema/tei_clarin.rng
	Stylesheets/bin/teitornc        ${PARAMS} ../schema/tei_clarin.rnc
	Stylesheets/bin/teitodtd        ${PARAMS} ../schema/tei_clarin.dtd
	Stylesheets/bin/teitoxsd        ${PARAMS} ../schema/tei_clarin.xsd
	Stylesheets/bin/teitoschematron ${PARAMS} ../schema/tei_clarin.sch

#This still needs to be implemented!
docs:	val-odd
	Stylesheets/bin/teitohtml --profiledir=$H --profile=profile --odd ${PARAMS} ../docs/index.html
	Stylesheets/bin/teitohtml --odd ${PARAMS} ../doc/tei_clarin_doc.html
	Stylesheets/bin/teitolite --odd ${PARAMS} ../doc/tei_clarin_doc.xml
H = /project/corpora/TEI-schema/bin/

j = java -jar /usr/share/java/jing.jar
s = java -jar /usr/share/java/saxon.jar

fix:
	$s -xsl:fix-c.xsl ../tei_clarin_example.xml > ../tei_clarin_example.new.xml
	$j ../schema/tei_clarin.rng ../tei_clarin_example.new.xml
