<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="fn tei">

  <xsl:output method="xml" encoding="utf-8" indent="yes" omit-xml-declaration="no"/>

  <xsl:template match="/">
    <tagsDecl xmlns="http://www.tei-c.org/ns/1.0">
      <namespace name="http://www.tei-c.org/ns/1.0">
	<xsl:apply-templates mode="tagCount" select="//tei:body"/>
      </namespace>
      </tagsDecl>
  </xsl:template>
  <xsl:template mode="tagCount" match="tei:*">
    <xsl:variable name="self" select="name()"/>
    <xsl:if test="not(following::tei:*[name()=$self] or descendant::tei:*[name()=$self] )">
      <tagUsage xmlns="http://www.tei-c.org/ns/1.0" gi="{$self}">
	<xsl:attribute name="occurs">
	  <xsl:number level="any" from="tei:body"/>
	</xsl:attribute>
      </tagUsage>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
    <xsl:apply-templates mode="tagCount"/>
  </xsl:template>
  <xsl:template mode="tagCount" match="text()"/>
</xsl:stylesheet>
