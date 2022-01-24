<?xml version="1.0"?>
<!-- Transform ssj500k 2.3 corpus to CQP vertical format -->
<xsl:stylesheet version="2.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:fn="http://www.w3.org/2005/xpath-functions"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns:et="http://nl.ijs.si/et/"
		xmlns="http://www.tei-c.org/ns/1.0"
		exclude-result-prefixes="tei fn et">
  <xsl:output method="xml" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <xsl:param name="taxo-sperator">/</xsl:param>
  <xsl:variable name="Root" select="/"/>

  <xsl:key name="id" match="tei:*" use="@xml:id"/>

  <xsl:template match="@*"/>
  <xsl:template match="text()"/>
  <xsl:template match="tei:TEI">
    <xsl:apply-templates select="//tei:text/tei:body/tei:div"/>
  </xsl:template>

  <xsl:template match="tei:div">
    <xsl:variable name="title">
      <xsl:call-template name="meta">
	<xsl:with-param name="element" select="tei:bibl/tei:title"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="author" >
      <xsl:call-template name="meta">
	<xsl:with-param name="element" select="tei:bibl/tei:author"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="publisher" >
      <xsl:call-template name="meta">
	<xsl:with-param name="element" select="tei:bibl/tei:publisher"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="date" >
      <xsl:call-template name="meta">
	<xsl:with-param name="element" select="tei:bibl/tei:date"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="year" >
      <xsl:call-template name="meta">
	<xsl:with-param name="element" select="replace(tei:bibl/tei:date,'-.+','')"/>
      </xsl:call-template>
    </xsl:variable>
    <text id="{@xml:id}" 
	  title="{$title}" author="{$author}" date="{$year}" publisher="{$publisher}">
      <xsl:variable name="medium_id"
		    select="tei:bibl/tei:term[@type='Ft'][@xml:lang='sl'][starts-with(@ref,'#Ft.P')]/@ref"/>
      <xsl:attribute name="medium_id">
	<xsl:call-template name="meta">
	  <xsl:with-param name="element" select="$medium_id"/>
	</xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="medium">
	<xsl:call-template name="taxo">
	  <xsl:with-param name="id" select="$medium_id"/>
	</xsl:call-template>
      </xsl:attribute>
      <xsl:variable name="type_id"
		    select="tei:bibl/tei:term[@type='Ft'][@xml:lang='sl'][starts-with(@ref,'#Ft.Z')]/@ref"/>
      <xsl:attribute name="type_id">
	<xsl:call-template name="meta">
	  <xsl:with-param name="element" select="$type_id"/>
	</xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="type">
	<xsl:call-template name="taxo">
	  <xsl:with-param name="id" select="$type_id"/>
	</xsl:call-template>
      </xsl:attribute>
      <xsl:variable name="proofread_id"
		    select="tei:bibl/tei:term[@type='Ft'][@xml:lang='sl'][starts-with(@ref,'#Ft.L')]/@ref"/>
      <xsl:attribute name="proofread_id">
	<xsl:call-template name="meta">
	  <xsl:with-param name="element" select="$proofread_id"/>
	</xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="proofread">
	<xsl:call-template name="taxo">
	  <xsl:with-param name="id" select="$proofread_id"/>
	</xsl:call-template>
      </xsl:attribute>
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates/>
    </text>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="tei:p | tei:s">
    <xsl:copy>
      <xsl:attribute name="id">
	<xsl:value-of select="@xml:id"/>
      </xsl:attribute>
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="tei:seg[@type = 'name']">
    <name type="{@subtype}">
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates/>
    </name>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="tei:c"/>
  
  <xsl:template match="tei:pc | tei:w">
    <xsl:value-of select="concat(.,'&#9;',et:output-annotations(.))"/>
    <xsl:call-template name="deps">
      <xsl:with-param name="type">JOS-SYN</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="grandparent">
      <xsl:with-param name="type">JOS-SYN</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="deps">
      <xsl:with-param name="type">UD-SYN</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="grandparent">
      <xsl:with-param name="type">UD-SYN</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="deps">
      <xsl:with-param name="type">SRL</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="mwe"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:if test="@join = 'right' or @join='both' or
		  following::tei:*[self::tei:w or self::tei:pc][1]/@join = 'left' or
		  following::tei:*[self::tei:w or self::tei:pc][1]/@join = 'both'">
      <g/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Output information about the head of the word -->
  <xsl:template name="deps">
    <xsl:param name="type"/>
    <xsl:variable name="id" select="@xml:id"/>
    <xsl:variable name="s" select="ancestor::tei:s"/>
    <xsl:choose>
      <xsl:when test="$s/tei:linkGrp[@type=$type]">
	<xsl:variable name="link"
		      select="$s/tei:linkGrp[@type=$type]/tei:link
			      [ends-with(@target,concat(' #',$id))]"/>
	<!-- We take the ID (but with (UD) _ changed to :) as the label -->
	<xsl:variable name="label" select="replace(
					   substring-after($link/@ana,':'),
					   '_', ':')"/>
	<xsl:value-of select="concat('&#9;',$label)"/>
	<xsl:variable name="head" select="key('id', replace($link/@target,'#(.+?) #.*','$1'))"/>
	<xsl:choose>
	  <xsl:when test="$head/self::tei:s">
	    <xsl:text>&#9;&#9;&#9;&#9;&#9;</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="concat('&#9;',et:output-annotations($head))"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Output the syntactic relation of the parent -->
  <xsl:template name="grandparent">
    <xsl:param name="type"/>
    <xsl:variable name="id" select="@xml:id"/>
    <xsl:variable name="s" select="ancestor::tei:s"/>
    <xsl:choose>
      <xsl:when test="$s/tei:linkGrp[@type=$type]">
	<xsl:variable name="parent"
		      select="$s/tei:linkGrp[@type=$type]/tei:link
			      [ends-with(@target,concat(' #',$id))]/
			      substring-before(@target, ' ')"/>
	<xsl:variable name="link"
		      select="$s/tei:linkGrp[@type=$type]/tei:link
			      [ends-with(@target, $parent)]"/>
	<!-- We take the ID (but with (UD) _ changed to :) as the label -->
	<xsl:variable name="label" select="replace(
					   substring-after($link/@ana,':'),
					   '_', ':')"/>
	<xsl:value-of select="concat('&#9;',$label)"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>&#9;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- If word is a part of MWE, output the type of MWE and the words and lemmas its MWE -->
  <xsl:template name="mwe">
    <xsl:variable name="id" select="@xml:id"/>
    <xsl:variable name="s" select="ancestor::tei:s"/>
    <xsl:variable name="type">
      <xsl:for-each select="$s/tei:linkGrp[@type='MWE']/tei:link">
	<xsl:variable name="class" select="substring-after(@ana, ':')"/>
	<xsl:for-each select="tokenize(@target, ' ')">
	  <xsl:if test=". = concat('#', $id)">
	    <xsl:value-of select="$class"/>
	  </xsl:if>
	</xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="normalize-space($type)">
	<xsl:variable name="mwe-lemmas">
	  <xsl:for-each select="$s/tei:linkGrp[@type='MWE']/tei:link">
	    <xsl:if test="contains(@target, concat('#', $id, ' ')) or
			  ends-with(@target, concat('#', $id))">
	      <xsl:for-each select="tokenize(@target, ' ')">
		<xsl:variable name="tok" select="key('id', replace(., '#', ''), $s)"/>
		<xsl:value-of select="concat($tok/@lemma, ' ')"/>
	      </xsl:for-each>
	    </xsl:if>
	  </xsl:for-each>
	</xsl:variable>
	<xsl:variable name="mwe-words">
	  <xsl:for-each select="$s/tei:linkGrp[@type='MWE']/tei:link">
	    <xsl:if test="contains(@target, concat('#', $id, ' ')) or
			  ends-with(@target, concat('#', $id))">
	      <xsl:for-each select="tokenize(@target, ' ')">
		<xsl:variable name="tok" select="key('id', replace(., '#', ''), $s)"/>
		<xsl:value-of select="concat(lower-case($tok/text()), ' ')"/>
	      </xsl:for-each>
	    </xsl:if>
	  </xsl:for-each>
	</xsl:variable>
	<xsl:value-of select="concat(
			      '&#9;', $type, 
			      '&#9;', normalize-space($mwe-words),
			      '&#9;', normalize-space($mwe-lemmas)
			      )"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>&#9;&#9;&#9;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="et:output-annotations">
    <xsl:param name="token"/>
    <xsl:variable name="msd" select="substring-after($token/@ana,'mte:')"/>
    <xsl:variable name="ud_pos" select="replace($token/@msd, 'UPosTag=([^|]+).*', '$1')"/>
    <xsl:variable name="ud_feats">
      <xsl:variable name="feats" select="replace($token/@msd, 'UPosTag=[^|]+\|?', '')"/>
      <xsl:if test="normalize-space($feats)">
	<xsl:value-of select="translate($feats, '_|', ': ')"/>
      </xsl:if>
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
    <xsl:sequence select="concat($lemma, '&#9;', $msd, '&#9;', $ud_pos, '&#9;', $ud_feats, 
			  '&#9;', $token/@xml:id)"/>
  </xsl:function>

  <xsl:template name="meta">
    <xsl:param name="element"/>
    <xsl:choose>
      <xsl:when test="starts-with($element,'#')">
	<xsl:value-of select="substring-after($element,'#')"/>
      </xsl:when>
      <xsl:when test="normalize-space($element)">
	<xsl:value-of select="normalize-space(replace($element,' / ','/'))"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="taxo">
    <xsl:param name="id"/>
    <xsl:param name="lang">sl</xsl:param>
    <xsl:variable name="t" select="/tei:TEI/tei:teiHeader/tei:encodingDesc/tei:classDecl/tei:taxonomy"/>
    <xsl:variable name="taxo">
      <xsl:for-each select="$t//tei:category[@xml:id = substring-after($id, '#')]/
			    ancestor-or-self::tei:category">
	<xsl:value-of select="replace(tei:catDesc/tei:term[@xml:lang = $lang], ' ', '_')"/>
	<xsl:if test="descendant::tei:category">
	  <xsl:value-of select="$taxo-sperator"/>
	</xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="normalize-space($taxo)">
      <xsl:call-template name="pathit">
	<xsl:with-param name="tail" select="$taxo"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="pathit">
    <xsl:param name="delimiter" select="$taxo-sperator"/>
    <xsl:param name="head"/>
    <xsl:param name="tail"/>
    <xsl:if test="normalize-space($head)">
      <xsl:value-of select="lower-case($head)"/>
      <xsl:if test="normalize-space($tail)">
	<xsl:text>,</xsl:text>
      </xsl:if>
    </xsl:if>
    <xsl:if test="normalize-space($tail)">
      <xsl:variable name="h">
	<xsl:choose>
	  <xsl:when test="contains($tail, $delimiter)">
	    <xsl:value-of select="substring-before($tail, $delimiter)"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$tail"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
      <xsl:variable name="t">
	<xsl:if test="contains($tail, $delimiter)">
	  <xsl:value-of select="substring-after($tail, $delimiter)"/>
	</xsl:if>
      </xsl:variable>
      <xsl:call-template name="pathit">
	<xsl:with-param name="head">
	  <xsl:if test="normalize-space($head)">
	    <xsl:value-of select="concat($head, $delimiter)"/>
	  </xsl:if>
	  <xsl:value-of select="$h"/>
	</xsl:with-param>
	<xsl:with-param name="tail" select="$t"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
