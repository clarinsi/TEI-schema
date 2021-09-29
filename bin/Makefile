test:
	grab-clarin.pl 11356/1434 ssj500k-en.TEI.zip > Origs/ssj500k-en/
	sample.pl ssj500k Origs/ssj500k-en/ ../samples/ssj500k
	show.pl ../samples/ssj500k

all:	schema val docs
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

H = /project/corpora/TEI-schema/bin/
docs:	val-odd
	Stylesheets/bin/teitohtml --profiledir=$H --profile=profile --odd ${PARAMS} \
	../docs/tei_clarin_doc.html

j = java -jar /usr/share/java/jing.jar
s = java -jar /usr/share/java/saxon.jar

fix:
	$s -xsl:fix-c.xsl ../tei_clarin_example.xml > ../tei_clarin_example.new.xml
	$j ../schema/tei_clarin.rng ../tei_clarin_example.new.xml
