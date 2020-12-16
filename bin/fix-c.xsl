<?xml version="1.0" encoding="utf-8"?>
<!-- Stylesheet to put replace c with @join="right"
     Input:
       <pc>"</pc>
       <w>Tistega</w><c> </c>
       <w>večera</w>
     Output:
       <pc join="right">"</pc>
       <w>Tistega</w>
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

  <xsl:template match="tei:c"/>
  <xsl:template match="tei:w | tei:pc">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="not(following::tei:*[1][self::tei:c] or
		    ancestor::tei:choice/following::tei:*[1][self::tei:c])">
	<xsl:attribute name="join">right</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
