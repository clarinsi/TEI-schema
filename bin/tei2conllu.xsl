<?xml version='1.0' encoding='UTF-8'?>
<!-- Convert CLARIN.SI TEI corpus to CoNLL-U:
- document (div or ab), paragraph (p) and sentence (s) IDs
- metadata on element attributes or contained bibl
- normalised words (w/w or w/pc)
- XPoS (w/@ana)
- UPoS and UD mophological features (w/@msd) and dependencies (s/linkGrp)
- SpaceAfter (w/@join)
- NER (name/@type or seg[@type='name']/@subtype) 
-->
<xsl:stylesheet
    version='2.0' 
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:et="http://nl.ijs.si/et"
    exclude-result-prefixes="#all">

  <!-- Filename of corpus root containing the corpus-wide metadata -->
  <xsl:param name="meta"/>
  
  <!-- Type of morphology to output, either UD or JOS -->
  <xsl:param name="morType">UD</xsl:param>
  
  <!-- Type of syntax to output, either UD-SYN or JOS-SYN -->
  <xsl:param name="synType">UD-SYN</xsl:param>
  
  <!-- Localisation lang. for morphology / syntax, only relevant for JOS(-SYN), either en or sl -->
  <xsl:param name="locLang">en</xsl:param>
  
  <!-- Specify what we call the normalised form in the MISC column -->
  <xsl:param name="NormalisedForm">Style=Coll|CorrectForm=</xsl:param>

  <!-- Specify what we call NE information in the MISC column -->
  <xsl:param name="NER">NER=</xsl:param>
  
  <!-- Metadata containing needed for prefixDefs and taxonomies -->
  <xsl:variable name="metaData">
    <xsl:choose>
      <!-- File with metadata given in $meta parameter -->
      <xsl:when test="normalize-space($meta)">
        <xsl:if test="not(doc-available($meta))">
          <xsl:message terminate="yes" select="concat('FATAL: root file ',
					       $meta, ' given as meta parameter not found !')"/>
        </xsl:if>
	<xsl:apply-templates mode="XInclude" select="document($meta)"/>
      </xsl:when>
      <!-- Metadata is in the input document -->
      <xsl:when test="//tei:teiHeader">
        <xsl:copy-of select="/"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">FATAL: no metadata found!</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:output encoding="utf-8" method="text"/>
  
  <xsl:key name="idr" match="tei:*" use="concat('#',@xml:id)"/>
  
  <!-- Do the document sentences contain names? If not, they won't be output in MISC as IOB -->
  <xsl:variable name="hasNE" as="xs:boolean">
    <xsl:choose>
      <xsl:when test="//tei:s/tei:name">
        <xsl:value-of select="true()"/>
      </xsl:when>
      <xsl:when test="//tei:s/tei:seg[@type = 'name']">
        <xsl:value-of select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:template match="tei:*">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="text()"/>

  <!-- A div containing paragraphs or ab containing sentences corresponds to a document -->
  <xsl:template match="tei:div[tei:p] | tei:ab[tei:s]">
    <xsl:variable name="content">
      <xsl:apply-templates/>
    </xsl:variable>
    <!-- Output only if non-empty -->
    <xsl:if test="normalize-space($content)">
      <xsl:value-of select="concat('# newdoc id = ', @xml:id, '&#10;')"/>
      <xsl:call-template name="metadata"/>
      <xsl:value-of select="$content"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:body//tei:p | tei:div//tei:p">
    <xsl:choose>
      <xsl:when test="tei:s">
        <xsl:value-of select="concat('# newpar id = ', @xml:id, '&#10;')"/>
        <xsl:call-template name="metadata"/>
        <xsl:apply-templates select="tei:s"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:value-of select="concat('WARN: skipping paragraph ', 
                                @xml:id, ' without sentences ', @xml:id)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:s">
    <xsl:value-of select="concat('# sent_id = ', @xml:id, '&#10;')"/>
    <xsl:call-template name="metadata"/>
    <xsl:variable name="text">
      <xsl:apply-templates mode="plain"/>
    </xsl:variable>
    <xsl:value-of select="concat('# text = ', normalize-space($text), '&#10;')"/>
    <xsl:apply-templates/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- We ignore these (and parents of desc) -->
  <xsl:template match="tei:note | tei:desc"/>

  <!-- Names will be stored in local column as IOB -->
  <xsl:template match="tei:name | tei:seg[@type='name']">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Output one token line -->
  <xsl:template match="tei:w | tei:pc">
    <!-- Get MSD feature-structure -->
    <xsl:variable name="fs">
      <xsl:if test="@ana">
	<xsl:copy-of select="et:msd-fs(@ana, $locLang)"/>
      </xsl:if>
    </xsl:variable>
    <!-- 1/ID -->
    <xsl:apply-templates mode="number" select="."/>
    <xsl:text>&#9;</xsl:text>

    <!-- 2/FORM -->
    <xsl:apply-templates mode="token" select="."/>
    <xsl:text>&#9;</xsl:text>

    <!-- 3/LEMMA -->
    <xsl:choose>
      <xsl:when test="self::tei:pc and not(@lemma)">
        <xsl:value-of select="substring(@lemma, 1, 1)"/>
      </xsl:when>
      <xsl:when test="@lemma">
        <xsl:value-of select="@lemma"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>_</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#9;</xsl:text>

    <!-- 4/UPOS  (UD PoS tag or JOS/MULTEXT-East CATEGORY) -->
    <xsl:choose>
      <xsl:when test="$morType = 'UD' and @msd">
        <xsl:variable name="catfeat" select="replace(@msd, '\|.+', '')"/>
        <xsl:value-of select="replace($catfeat, 'UPosTag=', '')"/>
      </xsl:when>
      <xsl:when test="$morType = 'JOS' and @ana">
	<!-- By convention CATEGORY (i.e. part-of-speech) is first feature -->
        <xsl:value-of select="$fs/tei:fs/tei:f[1]/tei:symbol/@value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>_</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#9;</xsl:text>

    <!-- 5/XPOS (JOS / MULTEXT-East MSD) -->
    <xsl:choose>
      <xsl:when test="@ana">
        <xsl:value-of select="$fs/tei:fs/@xml:id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>_</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#9;</xsl:text>

    <!-- 6/FEATS  (UD morphological features or JOS / MULTEXT-East MSD features ) -->
    <xsl:choose>
      <xsl:when test="$morType = 'UD' and @msd">
        <xsl:value-of select="et:ud2feats(@msd)"/>
      </xsl:when>
      <xsl:when test="$morType = 'JOS' and @ana">
        <xsl:value-of select="et:fs2feats($fs)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>_</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#9;</xsl:text>

    <!-- 7/HEAD -->
    <xsl:variable name="Syntax" select="ancestor::tei:s/tei:linkGrp[@type=$synType]"/>
    <xsl:choose>
      <xsl:when test="$Syntax//tei:link">
        <xsl:call-template name="head">
          <xsl:with-param name="id" select="@xml:id"/>
          <xsl:with-param name="links" select="$Syntax"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>_</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#9;</xsl:text>

    <!-- 8/DEPREL (UD or JOS / MULTEXT-East dependency relation -->
    <xsl:choose>
      <xsl:when test="$Syntax//tei:link">
        <xsl:call-template name="synRelation">
          <xsl:with-param name="id" select="@xml:id"/>
          <xsl:with-param name="links" select="$Syntax"/>
          <xsl:with-param name="locLang" select="$locLang"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>_</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#9;</xsl:text>
    
    <!-- 9/DEPS -->
    <xsl:text>_</xsl:text>
    <xsl:text>&#9;</xsl:text>

    <!-- 10/MISC: optional normalised form, named entity, glue -->
    <xsl:variable name="misc">
      <xsl:variable name="norm">
        <xsl:apply-templates mode="norm" select="."/>
      </xsl:variable>
      <xsl:variable name="ner">
        <xsl:if test="$hasNE">
          <xsl:call-template name="NER"/>
        </xsl:if>
      </xsl:variable>
      <xsl:variable name="glue">
        <xsl:call-template name="SpaceAfter">
          <xsl:with-param name="no">|SpaceAfter=No</xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="replace(
                            replace(
                            replace(
                            string-join(($norm, $ner, $glue), '|'),
                            '\|+', '|'),
                            '\|$', ''),
                            '^\|', '')"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="not(normalize-space($misc))">_</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$misc"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
    <!-- Now process 1-n nested normalised words -->
    <xsl:apply-templates select="tei:*[@ana]"/>
  </xsl:template>

  <!-- Output the plain text of a sentence -->
  <xsl:template mode="plain" match="text()"/>
  <xsl:template mode="plain" match="tei:*">
    <xsl:apply-templates mode="plain"/>
  </xsl:template>
  <xsl:template mode="plain" match="tei:w | tei:pc">
    <xsl:choose>
      <!-- n-1 -->
      <xsl:when test=".[@norm]/tei:*">
        <xsl:apply-templates mode="plain"/>
      </xsl:when>
      <!-- 1-n -->
      <xsl:when test="tei:*">
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:call-template name="SpaceAfter">
          <xsl:with-param name="yes">&#32;</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <!-- 1-1 -->
      <xsl:otherwise>
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:call-template name="SpaceAfter">
          <xsl:with-param name="yes">
            <xsl:text>&#32;</xsl:text>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Output value of ID column. 
       1-n normalised tokens are treated as syntactic words, 
       n-1 normalised tokens are treated as FORMs with spaces, eg.
       1       Naš     naš
       2-3     tastár  _
       2       ta      ta
       3       stari   star
       4       .       .
       
       1       gospa   gospa
       2       ma      imeti
       3       pelc montl      pelcmontel
       4       .       .
  -->
  <xsl:template mode="number" match="tei:*">
    <xsl:if test="not(self::tei:pc or self::tei:w)">
      <xsl:message terminate="yes">
        <xsl:value-of select="concat('ERROR: sequence number for non-token: ', text())"/>
      </xsl:message>
    </xsl:if>
    <!-- Number of words with annotation -->
    <xsl:variable name="simple">
      <xsl:variable name="n">
        <xsl:number count="tei:*[self::tei:w or self::tei:pc][@ana]"
                    level="any" from="tei:s"/>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="normalize-space($n)">
          <xsl:value-of select="$n"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <!-- n-1 -->
      <xsl:when test=".[@norm]/tei:*">
        <xsl:value-of select="$simple"/>
      </xsl:when>
      <!-- 1-n -->
      <xsl:when test="tei:w or tei:pc">
        <xsl:value-of select="$simple + 1"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$simple + count(tei:w | tei:pc)"/>
      </xsl:when>
      <!-- 1-1 -->
      <xsl:otherwise>
        <xsl:value-of select="$simple"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template mode="token" match="tei:*">
    <xsl:choose>
      <!-- n-1 -->
      <xsl:when test=".[@norm]/tei:*">
        <xsl:variable name="token">
          <xsl:apply-templates mode="plain"/>
        </xsl:variable>
        <xsl:value-of select="normalize-space($token)"/>
      </xsl:when>
      <!-- 1-1 -->
      <xsl:when test="normalize-space(.)">
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:when>
      <!-- 1-n -->
      <xsl:otherwise>
        <xsl:value-of select="@norm"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Copy input element to output with XIncluding the files (like parts of the teiHeader or <back>, 
       Do not XInclude anything in <body> (where the corpus) -->
  <xsl:template mode="XInclude" match="tei:body"/>
  <xsl:template mode="XInclude" match="xi:include">
    <xsl:apply-templates mode="XInclude" select="document(@href)"/>
  </xsl:template>
  <xsl:template mode="XInclude" match="tei:*">
    <xsl:copy>
      <xsl:apply-templates mode="XInclude" select="@*"/>
      <xsl:apply-templates mode="XInclude"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template mode="XInclude" match="@*">
    <xsl:copy/>
  </xsl:template>

  <!-- Output normalised form(s) of a token (in MISC column) -->
  <xsl:template mode="norm" match="tei:*">
    <!-- cf. https://universaldependencies.org/misc.html -->
    <!-- n-1 -->
    <xsl:choose>
      <!-- 1-n -->
      <!-- subordinate empty word with @norm: already present in the "syntactic" column, 
           should not mark it again in MISC -->
      <xsl:when test="not(normalize-space(.))"/>
      <xsl:when test="tei:*[@norm]">
        <xsl:value-of select="$NormalisedForm"/>
        <xsl:for-each select="tei:*">
          <xsl:value-of select="@norm"/>
          <xsl:if test="following-sibling::tei:*">
            <xsl:text>&#32;</xsl:text>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="@norm">
        <xsl:value-of select="concat($NormalisedForm, @norm)"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Output $no if token is @join-ed to next token, $yes otherwise -->
  <xsl:template name="SpaceAfter">
    <xsl:param name="yes">&#32;</xsl:param>
    <xsl:param name="no"/>
    <xsl:choose>
      <xsl:when test="@join = 'right' or @join='both' or
                      following::tei:*[self::tei:w or self::tei:pc][1]
                      [@join = 'left' or @join = 'both']">
        <xsl:value-of select="$no"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$yes"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Return the number of the head token -->
  <xsl:template name="head">
    <xsl:param name="links"/>
    <xsl:param name="id" select="@xml:id"/>
    <!-- the token id is the second id in the link/@target, hence ' #' -->
    <xsl:variable name="link" select="$links//tei:link[matches(@target, concat(' #', $id, '$'))]"/>
    <xsl:choose>
      <xsl:when test="($link/@ana)[2]">
	<xsl:message terminate="no" select="concat('ERROR: duplicate ', 
					    $synType, ' link for ', $id)"/>
	<xsl:text>???</xsl:text>
      </xsl:when>
      <xsl:when test="not(normalize-space($link/@ana))">
	<xsl:message terminate="no" select="concat('ERROR: cant find ', 
					    $synType, ' link for ', $id)"/>
	<xsl:text>???</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="head_id" select="replace($link/@target, ' .+', '')"/>
	<xsl:choose>
	  <xsl:when test="key('idr', $head_id)/name()= 's'">0</xsl:when>
	  <xsl:when test="key('idr', $head_id)[name()='pc' or name()='w']">
            <xsl:apply-templates mode="number" select="key('idr', $head_id)"/>
	  </xsl:when>
	  <xsl:otherwise>
            <xsl:message terminate="no"
			 select="concat('ERROR: in link for ', $id, 
				 ' cant find head [', $head_id, ']')"/>
	    <xsl:text>???</xsl:text>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Return the name of the syntactic relation (either UD or JOS, in en or sl -->
  <xsl:template name="synRelation">
    <xsl:param name="id"/>
    <xsl:param name="links"/>
    <xsl:param name="locLang"/>
    <!-- The link for focus token -->
    <!-- the token id is the second id in the link/@target, hence ' #' -->
    <xsl:variable name="link" select="$links//tei:link
                                      [matches(@target, concat(' #', $id, '$'))]"/>

    <xsl:choose>
      <xsl:when test="($link/@ana)[2]">
	<xsl:message terminate="no" select="concat('ERROR: duplicate ', 
					    $synType, ' link for ', $id)"/>
	<xsl:text>???</xsl:text>
      </xsl:when>
      <xsl:when test="not(normalize-space($link/@ana))">
	<xsl:message terminate="no" select="concat('ERROR: cant find ', 
					    $synType, ' relation for ', $id)"/>
	<xsl:text>???</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<!-- Locate the category definition in the taxonomy -->
	<xsl:variable name="category_orig"
		      select="et:key($link/@ana, $metaData)"/>
	<xsl:choose>
	  <!-- We couldn't find the original category in the taxonomy -->
	  <xsl:when test="not($category_orig/@xml:id)">
	    <xsl:message terminate="no" select="concat('ERROR: cant find synt. relation definiton for [', 
						$link/@ana, ']')"/>
	    <xsl:text>???</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <!-- Locate the translated category definition in the taxonomy (might not exist) -->
	    <xsl:variable name="category_tran"
			  select="et:key($category_orig/@corresp, $metaData)"/>
	    <!-- We need to replace underscore with colon (for UD, for JOS empty op) -->
	    <xsl:variable name="relation_orig"
			  select="replace($category_orig/@xml:id, '_', ':')"/>
	    <xsl:variable name="relation_tran"
			  select="replace($category_tran/@xml:id, '_', ':')"/>
	    
	    <xsl:choose>
	      <xsl:when test="$category_orig[@xml:lang = $locLang]">
		<xsl:value-of select="$relation_orig"/>
	      </xsl:when>
	      <xsl:when test="$category_tran[@xml:lang = $locLang]">
		<xsl:value-of select="$relation_tran"/>
	      </xsl:when>
	      <xsl:when test="normalize-space($relation_orig)">
		<xsl:value-of select="$relation_orig"/>
	      </xsl:when>
	    </xsl:choose>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Output NER feature (for MISC column) -->
  <xsl:template name="NER">
    <xsl:value-of select="$NER"/>
    <xsl:choose>
      <xsl:when test="ancestor::tei:name">
        <xsl:variable name="ancestor" select="generate-id(ancestor::tei:name[last()])"/>
        <xsl:variable name="type" select="ancestor::tei:name/@type"/>
        <xsl:choose>
          <xsl:when test="preceding::tei:*[1]
                          [ancestor::tei:*[generate-id(.) = $ancestor]]
                          ">
            <xsl:value-of select="concat('I-', $type)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('B-', $type)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="ancestor::tei:seg[@type = 'name']">
        <xsl:variable name="ancestor" select="generate-id(ancestor::tei:seg[@type = 'name'][last()])"/>
        <xsl:variable name="type" select="ancestor::tei:seg[@type = 'name']/@subtype"/>
        <xsl:choose>
          <xsl:when test="preceding::tei:*[1]
                          [ancestor::tei:*[generate-id(.) = $ancestor]]
                          ">
            <xsl:value-of select="concat('I-', $type)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('B-', $type)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>O</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Output metadata for element, either in element's attributes or in bibl -->
  <xsl:template name="metadata">
    <xsl:for-each select="@*">
      <xsl:if test="name() != 'xml:id' and name() != 'xml:lang' ">
        <xsl:value-of select="concat('# ', name(), ' = ', ., '&#10;')"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="tei:bibl/tei:*">
      <xsl:choose>
        <xsl:when test="self::tei:note[@type]">
          <xsl:value-of select="concat('# ', @type, ' = ', ., '&#10;')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('# ', name(), ' = ', ., '&#10;')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:function name="et:msd-fs" as="element(tei:fs)">
    <xsl:param name="ana"/>
    <xsl:param name="locLang"/>
    <xsl:variable name="msd-fs-origi" select="et:key($ana, $metaData)"/>
    <xsl:if test="not($msd-fs-origi/@xml:id)">
      <xsl:message terminate="yes"
		   select="concat('ERROR: cant find fs with reference ', $ana)"/>
    </xsl:if>
    <!-- We possibly need to change the reference of the translated FS to extened pointer syntax,
	 e.g. from #Xf to mte:Xf, otherwise we can't resolve it -->
    <xsl:variable name="fs-trans-ptr" select="et:extend-pointer($ana, $msd-fs-origi/@corresp)"/>
    <xsl:variable name="msd-fs-trans" select="et:key($fs-trans-ptr, $metaData)"/>
    <xsl:if test="not($msd-fs-trans/@xml:id)">
      <xsl:message terminate="no"
		   select="concat('ERROR: cant find trans fs with reference ', $msd-fs-origi/@corresp)"/>
    </xsl:if>
    <xsl:variable name="fs">
      <xsl:choose>
	<xsl:when test="$msd-fs-origi/@xml:lang = $locLang">
	  <xsl:copy-of select="$msd-fs-origi"/>
	</xsl:when>
	<xsl:when test="$msd-fs-trans/@xml:lang = $locLang">
	  <xsl:copy-of select="$msd-fs-trans"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message terminate="no"
		       select="concat('ERROR: cant find fs with reference ', $ana, 
			       ' in language ', $locLang)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$fs/tei:fs/tei:f">
	<xsl:copy-of select="$fs/tei:fs"/>
      </xsl:when>
      <xsl:when test="$fs/tei:fs[@feats]">
	<fs>
	  <xsl:copy-of select="$fs/tei:fs/@*[not(name()=feats)]"/>
	  <xsl:for-each select="tokenize($fs/tei:fs/@feats, ' ')">
	    <xsl:copy-of select="et:key(et:extend-pointer($ana, .), $metaData)"/>"/>
	  </xsl:for-each>
	</fs>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes" select="concat('WEIRD situation: ', $fs/@xml:id)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
    
    <!-- Change local reference to extended pointer on the basis of $extended -->
  <xsl:function name="et:extend-pointer">
    <xsl:param name="extended"/>
    <xsl:param name="input"/>
    <xsl:choose>
      <!-- The original reference is already local, so this input can stay that way too: -->
      <xsl:when test="starts-with($extended, '#')">
	  <xsl:value-of select="$input"/>
	</xsl:when>
	<!-- The original reference has exended pointer: -->
	<xsl:when test="contains($extended, ':')">
	  <!-- The prefix of the extended pointer: -->
	  <xsl:variable name="prefix" select="substring-before($extended, ':')"/>
	  <!-- Substitute local reference with extended pointer: -->
	  <xsl:value-of select="replace($input, '#', concat($prefix, ':'))"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message terminate="yes" select="concat('WEIRD situation: ', $extended)"/>
	</xsl:otherwise>
      </xsl:choose>
  </xsl:function>
  
  <xsl:function name="et:ud2feats">
    <xsl:param name="msd"/>
    <!-- Get rid of UPosTag in UD features -->
    <xsl:variable name="feats"
		  select="replace($msd, 'UPosTag=[^|]+\|?', '')"/>
    <xsl:choose>
      <xsl:when test="normalize-space($feats)">
        <xsl:value-of select="et:sort_feats($feats)"/>
      </xsl:when>
      <xsl:otherwise>_</xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
<!-- Convert MSD feature structure to CoNLL-U-like features -->
  <xsl:function name="et:fs2feats">
    <xsl:param name="fs"/>
    <xsl:variable name="feats">
      <xsl:for-each select="$fs/tei:fs/tei:f">
	<!-- By convention CATEGORY (i.e. part-of-speech) is first -->
	<xsl:if test="position() &gt; 1">
          <xsl:value-of select="@name"/>
	  <xsl:text>=</xsl:text>
          <xsl:value-of select="tei:symbol/@value"/>
	  <xsl:if test="following-sibling::tei:f">
	    <xsl:text>|</xsl:text>
	  </xsl:if>
	</xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="normalize-space($feats)">
        <xsl:value-of select="et:sort_feats($feats)"/>
      </xsl:when>
      <xsl:otherwise>_</xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="et:sort_feats">
    <xsl:param name="feats"/>
    <xsl:variable name="sorted">
      <xsl:for-each select="tokenize($feats, '\|')">
        <xsl:sort select="lower-case(.)" order="ascending"/>
        <xsl:value-of select="."/>
        <xsl:text>|</xsl:text>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="replace($sorted, '\|$', '')"/>
  </xsl:function>

  <!-- Resolve, like key, an (extended TEI) pointer into the $doc variable -->
  <!-- If reference is to an external document, resolve also -->
  <xsl:function name="et:key">
    <xsl:param name="val"/>
    <xsl:param name="doc"/>
    <!-- Resolve extended pointer syntax, if necessary -->
    <xsl:variable name="ptr" select="et:prefix-replace($val)"/>
    <xsl:choose>
      <!-- A fragment identifier, done -->
      <xsl:when test="starts-with($ptr, '#')">
	<xsl:copy-of select="key('idr', $ptr,  $doc)"/>
      </xsl:when>
      <!-- A reference to a document -->
      <xsl:otherwise>
	<xsl:variable name="document-uri" select="replace($ptr, '#.+', '')"/>
	<xsl:variable name="fragment-id" select="substring-after($ptr, '#')"/>
	<xsl:if test="not(doc-available($document-uri))">
          <xsl:message terminate="yes"
		       select="concat('Document ', $document-uri, 
			       ' in pointer ', $ptr, 
			       ' for value ', $val, 'not found')"/>
	</xsl:if>
	<xsl:choose>
	  <xsl:when test="normalize-space($fragment-id)">
	    <xsl:copy-of select="key('idr', concat('#', $fragment-id), document($document-uri))"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <!-- No fragment, return the complete document -->
	    <xsl:copy-of select="document($document-uri)"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Replace, if necessary, TEI extended pointer syntax of a pointer value with normal reference -->
  <xsl:function name="et:prefix-replace">
    <xsl:param name="val"/>
    <!-- If more than one, just take first -->
    <xsl:variable name="listPrefix" select="($metaData//tei:listPrefixDef)[1]"/>
    <xsl:choose>
      <xsl:when test="contains($val, ':')">
        <xsl:variable name="prefix" select="substring-before($val, ':')"/>
        <xsl:variable name="val-in" select="substring-after($val, ':')"/>
        <xsl:variable name="match" select="$listPrefix//tei:prefixDef[@ident = $prefix]
                                           /@matchPattern"/>
        <xsl:variable name="replace" select="$listPrefix//tei:prefixDef[@ident = $prefix]
                                             /@replacementPattern"/>
        <xsl:choose>
          <xsl:when test="not(normalize-space($replace))">
            <xsl:message terminate="yes"
			 select="concat('Couldnt find replacement pattern in listPrefixDef for ', $val)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="replace($val-in, $match, $replace)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$val"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>
