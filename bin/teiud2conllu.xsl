<?xml version='1.0' encoding='UTF-8'?>
<!-- Convert CLARIN.SI TEI format with UD morphology and possibly syntax to CONLL-U format -->
<!-- Deals also with normalised files, i.e. those using the choice/orig or choice/reg text streams -->
<!-- Assumes that the lingguistic annotations are on the normalised tokens -->
<!-- Examples:

     In:
     <s xml:id="tid.39.1">
       <name type="per">
         <w xml:id="tid.39.1.1" lemma="@badabumbadabum" ana="mte:Xa" msd="UposTag=SYM">@badabumbadabum</w>
       </name><c> </c>
       <w xml:id="tid.398801627148468224.1.2" lemma="verjetno" ana="mte:Rgp" msd="UposTag=ADV|Degree=Pos">verjetno</w><c> </c>
       ...
       
     Out:
     # sent_id = tid.398801627148468224.1
     # text = @badabumbadabum verjetno sta prepričana da si Kučan in da napoveduješ bigbang.
     1	@badabumbadabum	@badabumbadabum	SYM	Xa	_	-1	-	_	_
     2	verjetno	verjetno	ADV	Rgp	Degree=Pos	-1	-	_	_

     In:
     <choice xml:id="tid.39.1.11">
       <orig>
         <w xml:id="tid.39.1.11.o1">bigbang</w>
       </orig>
       <reg>
         <w xml:id="tid.39.1.11.r1" lemma="big" ana="mte:Xf" msd="UposTag=X|Foreign=Yes">big</w><c> </c>
         <w xml:id="tid.39.1.11.r2" lemma="bang" ana="mte:Xf" msd="UposTag=X|Foreign=Yes">bang</w>
       </reg>
      </choice>
      <pc xml:id="tid.39.1.12" ana="mte:Z" msd="UposTag=PUNCT">.</pc>
      
      Out:
      11-12	bigbang	_	_	_	_	_	_	_	SpaceAfter=No
      11	big	big	X	Xf	Foreign=Yes	-1	-	_	_
      12	bang	bang	X	Xf	Foreign=Yes	-1	-	_	_
      13	.	.	PUNCT	Z	_	-1	-	_	_

      In:
      <choice xml:id="tid.53.4.2">
        <orig>
          <w xml:id="tid.53.4.2.o1">redko</w><c> </c>
          <w xml:id="tid.53.4.2.o2">kje</w>
        </orig>
        <reg>
          <w xml:id="tid.53.4.2.r1" lemma="redkokje" ana="mte:Rgp" msd="UposTag=ADV|Degree=Pos">redkokje</w>
            </reg>
         </choice><c> </c>

      Out:
      2	redko kje	redkokje	ADV	Rgp	Degree=Pos	-1	-	_	Normalized=redkokje

      In:
      <choice xml:id="janes.blog.rtvslo.5192.7.4.2">
        <orig>
          <w xml:id="janes.blog.rtvslo.5192.7.4.2.o1">s</w><c> </c>
          <w xml:id="janes.blog.rtvslo.5192.7.4.2.o2">ez</w>
        </orig>
        <reg>
          <w xml:id="janes.blog.rtvslo.5192.7.4.2.r1" lemma="se" ana="mte:Px" msd="UposTag=PRON|PronType=Prs|Reflex=Yes|Variant=Short">se</w><c> </c>
          <w xml:id="janes.blog.rtvslo.5192.7.4.2.r2" lemma="z" ana="mte:Si" msd="UposTag=ADP|Case=Ins">z</w>
        </reg>
      </choice><c> </c>

      Out:
      2-3	s ez	_	_	_	_	_	_	_	_
      2	se	se	PRON	Px	PronType=Prs|Reflex=Yes|Variant=Short	-1	-	_	_
      3	z	z	ADP	Si	Case=Ins	-1	-	_	_
-->
      
<xsl:stylesheet version='2.0' 
  xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:et="http://nl.ijs.si/et"
  exclude-result-prefixes="fn tei et">

  <xsl:key name="id" match="tei:*" use="concat('#',@xml:id)"/>
  <xsl:key name="corresp" match="tei:*" use="substring-after(@corresp,'#')"/>

  <!-- TEI prefix replacement mechanism -->
  <xsl:variable name="prefixes" select="//tei:listPrefixDef"/>

  <!--xsl:output encoding="utf-8" method="xml" indent="yes"/-->
  <xsl:output encoding="utf-8" method="text"/>
  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="tei:c"/>

  <!-- Process only sentences -->
  <xsl:template match="/">
    <xsl:apply-templates select="//tei:s"/>
  </xsl:template>
  
  <xsl:template match="tei:s">
    <xsl:value-of select="concat('# sent_id = ',@xml:id, '&#10;')"/>
    <xsl:variable name="text">
      <xsl:apply-templates mode="plain"/>
    </xsl:variable>
    <xsl:value-of select="concat('# text = ', normalize-space($text), '&#10;')"/>
    <xsl:apply-templates/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  
  <!-- Output plain text -->
  <xsl:template mode="plain" match="tei:w | tei:pc">
    <xsl:value-of select="."/>
  </xsl:template>
  <xsl:template mode="plain" match="tei:c">
    <xsl:text>&#32;</xsl:text>
  </xsl:template>
  <xsl:template mode="plain" match="tei:choice">
    <xsl:apply-templates mode="plain" select="tei:orig"/>
  </xsl:template>
  <xsl:template mode="plain" match="tei:*">
    <xsl:apply-templates mode="plain"/>
  </xsl:template>
  <xsl:template mode="plain" match="text()"/>
  
  <!-- Output annotated sentence tokens -->
  <xsl:template match="tei:c"/>
  <xsl:template match="tei:w | tei:pc">
    <xsl:apply-templates mode="output" select="."/>
  </xsl:template>
  <xsl:template match="tei:choice">
    <xsl:choose>
      <!-- Two or more original tokens, two or more normalised tokens -->
      <!-- this really shouldn't happen, but does... -->
      <xsl:when test="tei:orig/tei:*[2] and tei:reg/tei:*[2]">
	<!-- Surface tokens -->
	<xsl:apply-templates mode="output" select="tei:orig/tei:*[last()]">
	  <xsl:with-param name="id">
	    <xsl:apply-templates mode="number" select="tei:reg/tei:*[1]"/>
	    <xsl:text>-</xsl:text>
	    <xsl:apply-templates mode="number" select="tei:reg/tei:*[last()]"/>
	  </xsl:with-param>
	  <xsl:with-param name="token">
	    <!-- Space-merge all original tokens (including <c>) -->
	    <xsl:for-each select="tei:orig/tei:*">
	      <xsl:value-of select="."/>
	    </xsl:for-each>
	  </xsl:with-param>
	  <xsl:with-param name="lemma">_</xsl:with-param>
	  <xsl:with-param name="cpostag">_</xsl:with-param>
	  <xsl:with-param name="xpostag">_</xsl:with-param>
	  <xsl:with-param name="feats">_</xsl:with-param>
	  <xsl:with-param name="head">_</xsl:with-param>
	  <xsl:with-param name="deprel">_</xsl:with-param>
	  <xsl:with-param name="jos">_</xsl:with-param>
	</xsl:apply-templates>
	<!-- "Syntactic" tokens (not allowed to have spacing information) -->
	<xsl:for-each select="tei:reg/tei:*">
	  <xsl:apply-templates mode="output" select=".">
	    <xsl:with-param name="space"/>
	  </xsl:apply-templates>
	</xsl:for-each>
      </xsl:when>
      <!-- Two or more original tokens, 1 normalised token -->
      <xsl:when test="tei:orig/tei:*[2]">
	<!-- Output info on syntactic token, but output merged surface tokens -->
	<xsl:apply-templates mode="output" select="tei:reg/tei:*">
	  <xsl:with-param name="token">
	    <!-- Space-merge all original tokens (including <c>) -->
	    <xsl:for-each select="tei:orig/tei:*">
	      <xsl:value-of select="."/>
	    </xsl:for-each>
	  </xsl:with-param>
	  <!-- Also output normalised token -->
	  <xsl:with-param name="norm" select="tei:reg/tei:*/text()"/>
	</xsl:apply-templates>
      </xsl:when>
      <!-- 1 original token, two or more normalised tokens -->
      <xsl:when test="tei:reg/tei:*[2]">
	<!-- Surface token line -->
	<xsl:apply-templates mode="output" select="tei:orig/tei:*">
	  <xsl:with-param name="id">
	    <xsl:apply-templates mode="number" select="tei:reg/tei:*[1]"/>
	    <xsl:text>-</xsl:text>
	    <xsl:apply-templates mode="number" select="tei:reg/tei:*[last()]"/>
	  </xsl:with-param>
	  <xsl:with-param name="lemma">_</xsl:with-param>
	  <xsl:with-param name="cpostag">_</xsl:with-param>
	  <xsl:with-param name="xpostag">_</xsl:with-param>
	  <xsl:with-param name="feats">_</xsl:with-param>
	  <xsl:with-param name="head">_</xsl:with-param>
	  <xsl:with-param name="deprel">_</xsl:with-param>
	  <xsl:with-param name="jos">_</xsl:with-param>
	</xsl:apply-templates>
	<!-- "Syntactic" tokens (not allowed to have spacing information) -->
	<xsl:for-each select="tei:reg/tei:*">
	  <xsl:apply-templates mode="output" select=".">
	    <xsl:with-param name="space"/>
	  </xsl:apply-templates>
	</xsl:for-each>
      </xsl:when>
      <!-- 1-1 mapping (also output normalised token) -->
      <xsl:otherwise>
	<xsl:apply-templates mode="output" select="tei:reg/tei:*">
	  <xsl:with-param name="token" select="tei:orig/tei:*"/>
	  <xsl:with-param name="norm" select="tei:reg/tei:*/text()"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Output annotations for one token -->
  <xsl:template mode="output" match="tei:*"/>
  <xsl:template mode="output" match="tei:w | tei:pc">
    <!-- Sentence index for token -->
    <xsl:param name="id">
      <xsl:apply-templates mode="number" select="."/>
    </xsl:param>
    <!-- Token  -->
    <xsl:param name="token" select="text()"/>
    <!-- Normalised form of word -->
    <xsl:param name="norm"/>
    <!-- Lemma form of word -->
    <xsl:param name="lemma">
      <xsl:choose>
	<xsl:when test="self::tei:pc">
	  <xsl:value-of select="substring($token, 1, 1)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="@lemma"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <!-- UD part-of-speech tag, encoded as first feature of @msd as "UposTag=X" -->
    <xsl:param name="cpostag">
      <xsl:variable name="catfeat" select="replace(@msd, '\|.+', '')"/>
      <xsl:value-of select="replace($catfeat, 'UposTag=', '')"/>
    </xsl:param>
    <!-- MULTEXT-East MSD, encoded as (some sort of pointer) value of @ana -->
    <xsl:param name="xpostag">
      <xsl:choose>
	<xsl:when test="starts-with(@ana, '#')">
	  <xsl:value-of select="substring-after(@ana, '#')"/>
	</xsl:when>
	<xsl:when test="contains(@ana, ':')">
	  <xsl:value-of select="substring-after(@ana, ':')"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="@ana"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <!-- UD features, encoded as tail features of @msd -->
    <xsl:param name="feats">
      <xsl:variable name="fs" select="replace(@msd, 'UposTag=[^|]+\|?', '')"/>
      <xsl:choose>
	<xsl:when test="normalize-space($fs)">
	  <!-- In TEI ":" was changed to "_" so it doesn't clash with value prefixes -->
	  <xsl:value-of select="replace($fs, '_', ':')"/>
	</xsl:when>
	<xsl:otherwise>_</xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <!-- Head of UD syntactic relation -->
    <xsl:param name="head">
      <xsl:variable name="Syntax"
		    select="key('corresp',ancestor::tei:s[1]/@xml:id)[@type='UD-SYN']"/>
      <xsl:choose>
	<xsl:when test="$Syntax//tei:link">
	  <xsl:call-template name="head">
	    <xsl:with-param name="links" select="$Syntax"/>
	  </xsl:call-template>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:text>-1</xsl:text>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <!-- Dependency label of UD syntactic relation -->
    <xsl:param name="deprel">
      <xsl:variable name="Syntax"
		    select="key('corresp',ancestor::tei:s[1]/@xml:id)[@type='UD-SYN']"/>
      <xsl:choose>
	<xsl:when test="$Syntax//tei:link">
	  <xsl:call-template name="rel">
	    <xsl:with-param name="links" select="$Syntax"/>
	  </xsl:call-template>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:text>-</xsl:text>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <!-- Language specific feature: JOS dependency -->
    <xsl:param name="jos">
      <!-- JOS dependency syntax: head index and relation -->
      <xsl:variable name="Syntax"
		    select="key('corresp',ancestor::tei:s[1]/@xml:id)[@type='JOS-SYN']"/>
      <xsl:if test="$Syntax//tei:link">
	<xsl:text>Dep=</xsl:text>
	<xsl:call-template name="head">
	  <xsl:with-param name="links" select="$Syntax"/>
	</xsl:call-template>
	<xsl:text>|</xsl:text>
	<xsl:text>Rel=</xsl:text>
	<xsl:call-template name="rel">
	  <xsl:with-param name="links" select="$Syntax"/>
	</xsl:call-template>
      </xsl:if>
    </xsl:param>
    <!-- Language specific feature: Is token followed by space? -->
    <xsl:param name="space">
      <!-- If original token is ancestor, then we need to know if a space follows choice -->
      <xsl:choose>
	<xsl:when test="ancestor::tei:orig">
	  <xsl:apply-templates mode="space" select="ancestor::tei:choice"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates mode="space" select="."/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:param>

    <!-- Construct language specific features -->
    <xsl:variable name="misc">
      <xsl:variable name="normalised">
	<xsl:if test="normalize-space($norm)">
	  <xsl:text>Normalized=</xsl:text>
	  <xsl:value-of select="$norm"/>
	</xsl:if>
      </xsl:variable>
      <xsl:variable name="all" select="replace(
				       replace(
				       replace(
				       concat($normalised, '|', $space, '|', $jos),
				       '_', ''),
				       '^\|+', ''),
				       '\|+$', '')"/>
      <xsl:choose>
	<xsl:when test="normalize-space($all)">
	  <xsl:value-of select="$all"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:text>_</xsl:text>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- 1/ID -->
    <xsl:value-of select="$id"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 2/FORM -->
    <xsl:value-of select="$token"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 3/LEMMA -->
    <xsl:value-of select="$lemma"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 4/CPOSTAG -->
    <!-- e.g. ana="mte:Xf" msd="UposTag=X|Foreign=Yes" -->
    <xsl:value-of select="$cpostag"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 5/XPOS -->
    <xsl:value-of select="$xpostag"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 6/FEATS -->
    <xsl:value-of select="$feats"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 7/HEAD -->
    <xsl:value-of select="$head"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 8/DEPREL -->
    <xsl:value-of select="$deprel"/>
    <xsl:text>&#9;</xsl:text>
    <!-- 9/DEPS -->
    <xsl:text>_</xsl:text>
    <xsl:text>&#9;</xsl:text>
    <!-- 10/MISC -->
    <xsl:value-of select="$misc"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- Return the number of the head token -->
  <xsl:template name="head">
    <xsl:param name="links"/>
    <xsl:param name="id" select="@xml:id"/>
    <xsl:variable name="link" select="$links//tei:link[fn:matches(@target,concat(' #',$id,'$'))]"/>
    <xsl:variable name="head_id" select="substring-before($link/@target,' ')"/>
    <xsl:choose>
      <xsl:when test="key('id',$head_id)/name()= 's'">0</xsl:when>
      <xsl:when test="key('id',$head_id)[name()='pc' or name()='w']">
	<xsl:apply-templates mode="number" select="key('id',$head_id)"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:value-of select="concat('ERROR: in link cant find head ', $head_id, ' for id ', $id)"/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="number" match="tei:*">
    <xsl:number count="tei:w[not(parent::tei:orig)] | tei:pc[not(parent::tei:orig)]"
 		level="any" from="tei:s"/>
  </xsl:template>

  <!-- Does a space follow the element? -->
  <xsl:template mode="space" match="tei:*">
    <!-- Closest ancestor where space after token is implied -->
    <xsl:variable name="ancestor">
      <xsl:choose>
	<xsl:when test="ancestor::tei:p">
	  <xsl:value-of select="generate-id(ancestor::tei:p)"/>
	</xsl:when>
	<xsl:when test="ancestor::tei:ab">
	  <xsl:value-of select="generate-id(ancestor::tei:ab[1])"/>
	</xsl:when>
	<xsl:when test="ancestor::tei:div">
	  <xsl:value-of select="generate-id(ancestor::tei:div[1])"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message terminate="yes">No appropriate ancestor found</xsl:message>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- If a token inside the same $ancestor follows, and it is not a <c>, then no space after -->
    <!-- This in fact doesn't work for original tokens, as normalised tokens will follow, but
	 these should not be taken into account; we are lucky, as this template is always called
	 on normalised tokens, and these, by convention, follow original tokens -->
    <xsl:if test="following::tei:*[self::tei:w or self::tei:pc or self::tei:c][1]/
		  ancestor::tei:*[generate-id(.) = $ancestor]
		  and
		  not(following::tei:*[self::tei:w or self::tei:pc or self::tei:c][1][self::tei:c])
		  ">
      <xsl:text>SpaceAfter=No</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- Return the name of the syntactic relation -->
  <xsl:template name="rel">
    <xsl:param name="links"/>
    <xsl:param name="id" select="@xml:id"/>
    <xsl:variable name="link" select="$links//tei:link[fn:matches(@target,concat(' #',$id,'$'))]"/>
    <xsl:variable name="ana" select="et:prefix-replace($link/@ana, $prefixes)"/>
    <!-- In TEI ":" was changed to "_" so it doesn't clash with value prefixes -->
    <xsl:value-of select="replace(substring-after($link/$ana,'#'), '_', ':')"/>
  </xsl:template>

  <xsl:function name="et:prefix-replace">
    <xsl:param name="val"/>
    <xsl:param name="prefixes"/>
    <xsl:choose>
      <xsl:when test="contains($val, ':')">
	<xsl:variable name="prefix" select="substring-before($val, ':')"/>
	<xsl:variable name="val-in" select="substring-after($val, ':')"/>
	<xsl:variable name="match" select="$prefixes//tei:prefixDef[@ident = $prefix]/@matchPattern"/>
	<xsl:variable name="replace" select="$prefixes//tei:prefixDef[@ident = $prefix]/@replacementPattern"/>
	<xsl:choose>
	  <xsl:when test="not(normalize-space($replace))">
	    <xsl:message terminate="yes">
	      <xsl:value-of select="concat('Couldnt find replacement pattern in listPrefixDef for ', $val)"/>
	    </xsl:message>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="fn:replace($val-in, $match, $replace)"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$val"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>
