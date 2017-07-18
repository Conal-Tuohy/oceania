<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
>
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates>
				<xsl:sort select="substring-before(@name, '.')" data-type="number"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>

