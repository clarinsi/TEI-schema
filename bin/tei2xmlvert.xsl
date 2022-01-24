<?xml version="1.0"?>
<!-- Transform one TEI to CQP vertical format.
     Note that the output is still in XML, and needs another polish. -->
<!-- Needs the file with corpus teiHeader as a parameter -->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" 
    xmlns:et="http://nl.ijs.si/et"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    exclude-result-prefixes="fn et tei xs xi"
    version="2.0">

  <xsl:output method="xml" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>
  
  <!-- File with corpus teiHeader for information about taxonomies, persons, parties -->
  <xsl:param name="hdr"/>

  <xsl:key name="id" match="tei:*" use="@xml:id"/>

  <xsl:variable name="teiHeader">
    <xsl:if test="not(doc-available($hdr))">
      <xsl:message terminate="yes">
	<xsl:text>TEI header file </xsl:text>
	<xsl:value-of select="$hdr"/>
	<xsl:text> not found!</xsl:text>
      </xsl:message>
    </xsl:if>
     <xsl:copy-of select="document($hdr)"/>
  </xsl:variable>

  <xsl:template match="@*"/>
  <xsl:template match="text()"/>

  <xsl:template match="tei:TEI">
    <xsl:variable name="id" select="replace(@xml:id, '\.ana', '')"/>
    <xsl:variable name="titleStmt" select="tei:teiHeader/tei:fileDesc/tei:titleStmt"/>
    <xsl:variable name="sourceDesc" select="tei:teiHeader/tei:fileDesc/tei:sourceDesc"/>
    <xsl:variable name="digitalSource" select="$sourceDesc/tei:bibl[@type='digitalSource']"/>
    <xsl:variable name="source"
		  select="$sourceDesc/tei:bibl[@type='printSource' or @type='manuscriptSource']"/>
    <xsl:variable name="digitalSource" select="$sourceDesc/tei:bibl[@type='digitalSource']"/>
    
    <xsl:variable name="title" select="replace($titleStmt/tei:title[@type='main'], ' \[.+?\]', '')"/>
    <xsl:variable name="year">
      <!--xsl:if test="$source/tei:date/@cert = 'low'">?</xsl:if-->
      <xsl:value-of select="$source/tei:date/@when"/>
    </xsl:variable>
    <xsl:variable name="url">
      <xsl:choose>
	<xsl:when test="$digitalSource/tei:idno[@type='url']">
	  <xsl:value-of select="$digitalSource/tei:idno[@type='url']"/>
	</xsl:when>
	<xsl:when test="$digitalSource/tei:idno[@type='urn']">
	  <xsl:text>https://www.dlib.si/details/</xsl:text>
	  <xsl:value-of select="$digitalSource/tei:idno[@type='urn']"/>
	</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="author" select="$source/tei:author"/>
    <xsl:variable name="author_url" select="$source/tei:author/@ref"/>
    <xsl:variable name="translator" select="$source/tei:respStmt/tei:name"/>
    
    <text id="{$id}" title="{$title}" year="{$year}" url="{$url}"
	  author="{$author}" author_url="{$author_url}" translator="{$translator}">
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select="tei:text/tei:body/tei:ab"/>
    </text>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="tei:ab">
    <p id="{@xml:id}">
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates/>
    </p>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="tei:s">
    <xsl:copy>
      <xsl:attribute name="id" select="@xml:id"/>
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- TOKENS -->
  <xsl:template match="tei:pc | tei:w">
    <xsl:value-of select="concat(.,'&#9;',et:output-annotations(.))"/>
    <xsl:call-template name="deps"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:if test="@join = 'right' or @join='both' or
		  following::tei:*[self::tei:w or self::tei:pc][1]/@join = 'left' or
		  following::tei:*[self::tei:w or self::tei:pc][1]/@join = 'both'">
      <g/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- NAMED TEMPLATES -->

  <xsl:template name="deps">
    <xsl:param name="type">UD-SYN</xsl:param>
    <xsl:variable name="id" select="@xml:id"/>
    <xsl:variable name="s" select="ancestor::tei:s"/>
    <xsl:choose>
      <xsl:when test="$s/tei:linkGrp[@type=$type]">
	<xsl:variable name="link"
		      select="$s/tei:linkGrp[@type=$type]/tei:link
			      [ends-with(@target, concat(' #',$id))]"/>
	<xsl:if test="not(normalize-space($link/@ana))">
	  <xsl:message>
	    <xsl:text>ERROR: no syntactic link for token </xsl:text>
	    <xsl:value-of select="concat(ancestor::tei:TEI/@xml:id, ':', @xml:id)"/>
	  </xsl:message>
	</xsl:if>
	<xsl:value-of select="concat('&#9;', substring-after($link/@ana,'syn:'))"/>
	<xsl:variable name="target" select="key('id', replace($link/@target,'#(.+?) #.*','$1'))"/>
	<xsl:choose>
	  <xsl:when test="$target/self::tei:s">
	    <xsl:text>&#9;-&#9;-&#9;-&#9;-&#9;-&#9;-&#9;-</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="concat('&#9;', et:output-annotations($target))"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>
	  <xsl:text>ERROR: no linkGroup for sentence </xsl:text>
	  <xsl:value-of select="ancestor::tei:s/@xml:id"/>
	</xsl:message>
	<xsl:text>&#9;-&#9;-&#9;-&#9;-&#9;-&#9;-</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- FUNCTIONS -->

  <xsl:function name="et:output-annotations">
    <xsl:param name="token"/>
    <xsl:variable name="n" select="replace($token/@xml:id, '.+\.t?(\d+)$', 'tok$1')"/>
    <xsl:variable name="norm">
      <xsl:choose>
	<xsl:when test="$token/@norm">
	  <xsl:value-of select="$token/@norm"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="$token"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="lemma">
      <xsl:choose>
	<xsl:when test="$token/@lemma">
	  <xsl:value-of select="$token/@lemma"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="substring($token,1,1)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="msd" select="replace($token/@ana, '.+?:', '')"/>
    <xsl:variable name="ud-pos" select="replace(replace($token/@msd, 'UposTag=', ''), '\|.+', '')"/>
    <xsl:variable name="ud-feats">
      <xsl:variable name="fs" select="replace($token/@msd, 'UposTag=[^|]+\|?', '')"/>
      <xsl:choose>
	<xsl:when test="normalize-space($fs)">
	  <!-- Change source pipe to whatever we have for multivalued attributes -->
	  <xsl:value-of select="replace($fs, '\|', ' ')"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:text>_</xsl:text>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="concat($norm, '&#9;', $lemma, '&#9;', 
			  $msd, '&#9;', $ud-pos, '&#9;', $ud-feats, '&#9;', $n)"/>
  </xsl:function>

</xsl:stylesheet>
