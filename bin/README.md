# Support scripts for formatting CLARIN.SI corpora

* fix-cEOL.xsl: Puts `<c> </c>`, i.e. whitespace in an linguistically analysed text into the
  same line as the preceding token
* tei2conllu.xsl: converts a CLARIN.SI TEI encoded corpus with
  MTE+UD(+JOS) morphosyntactic and syntactic annotations into CoNLL-U format

Data to support ODD development:
* tei_odds.rng: Schema for validating the tei_clarin ODD
* p5subset.xml: Subset of TEI P5 (needed for generating XML schemas from ODD)
