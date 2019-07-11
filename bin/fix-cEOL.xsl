<?xml version="1.0" encoding="utf-8"?>
<!-- Stylesheet to put "<c> </c>", i.e. whitespace in an linguistically analysed text -->
<!-- into the same line as the preceding token. E.g.:
     Input:
       <pc>"</pc>
       <w>Tistega</w>
       <c> </c>
       <w>večera</w>
     Output:
       <pc>"</pc>
       <w>Tistega</w><c> </c>
       <w>večera</w>
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:fn="http://www.w3.org/2005/xpath-functions"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns="http://www.tei-c.org/ns/1.0"
		exclude-result-prefixes="fn tei" version="2.0">
  <xsl:output indent="no" method="xml" encoding="utf-8" omit-xml-declaration="no"/>

  <xsl:template match="tei:*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:choose>
      <xsl:when test="following-sibling::tei:*[1][self::tei:c]"/>
      <xsl:otherwise>
	<xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
