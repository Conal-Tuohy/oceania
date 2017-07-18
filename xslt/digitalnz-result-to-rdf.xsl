<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns="tag:oceania.digital,2017:digitalnz#">
	<xsl:template match="/result">
		<rdf:RDF xml:base="http://oceania.digital/digitalnz/">
			<rdf:Description rdf:about="item-{id}#">
				<xsl:variable name="leaf-node-elements" select=".//*[not(*)]"/>
				<xsl:for-each select="$leaf-node-elements">
					<xsl:element name="{local-name()}">
						<xsl:apply-templates select="." mode="type"/>
						<xsl:choose>
							<xsl:when test="ends-with(local-name(.), '-url')">
								<xsl:attribute name="rdf:resource" select="."/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="."/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:element>
				</xsl:for-each>
			</rdf:Description>
		</rdf:RDF>
	</xsl:template>
	
	<xsl:template mode="type" match="*[@type='integer']">
		<xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#int</xsl:attribute>
	</xsl:template>
	<xsl:template mode="type" match="*[@type='dateTime']">
		<xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#dateTime</xsl:attribute>
	</xsl:template>
	<xsl:template mode="type" match="*"/>
	
</xsl:stylesheet>

