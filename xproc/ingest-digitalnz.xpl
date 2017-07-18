<?xml version="1.0"?>
<!--
   Copyright 2017 Conal Tuohy

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->
<p:declare-step
	name="main"
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:oceania="https://github.com/Conal-Tuohy/oceania"
	xmlns:sparql="tag:conaltuohy.com,2017:sparql"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9"
>
	<!-- import calabash extension library to enable use of exproc steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<!-- the SPARQL Protocols -->
	<p:import href="sparql.xpl"/>
		
	<p:option name="directory" required="true"/>
		
	<!--<sparql:update query="drop all" service-uri="http://oceania.digital:8080/fuseki/oceania/update"/>-->
	<oceania:list-files name="list-of-xml-files-harvested-from-digitalnz">
		<p:with-option name="directory" select="$directory"/>
	</oceania:list-files>
<!--	<p:filter name="selection-of-files-to-ingest" select="//c:file"/>--><!-- currently ingest all -->
	<oceania:ingest/>

	<p:declare-step type="oceania:list-files" name="list-files">
		<p:output port="result" sequence="true"/>
		<p:option name="directory" required="true"/>
		<p:directory-list include-filter=".*\.xml">
			<p:with-option name="path" select="$directory"/>
		</p:directory-list>
		<cx:message name="sorting" message="Sorting data files ..."/>
		<p:xslt name="sort-files">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/sort-files.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step type="oceania:ingest" name="ingest">
		<p:input port="manifest"/>
		<!-- process each metadata file containing a batch of records-->
		<cx:message name="ingesting" message="Ingesting data files ..."/>
		<p:for-each name="list-of-files">
			<p:iteration-source select="//c:file"/><!-- all the files in the directory listing -->
			<p:add-xml-base/>
			<cx:message name="ingesting-file">
				<p:with-option name="message" select="concat('Ingesting ', /c:file/@name, ' ...')"/>
			</cx:message>
			<p:load name="batch-of-records">
				<p:with-option name="href" select="concat(/c:file/@xml:base, /c:file/@name)"/>
			</p:load>
			<!-- Catch any "-url" fields which don't start with "http" and re-encode their text value as a data: URI -->
			<cx:message name="encoding-data-uris" message="Encoding text as data: URIs ..."/>
			<p:string-replace name="convert-free-text-to-data-uri" 
				match="
					*
						[ends-with(local-name(.), '-url')]
						[not(starts-with(., 'http'))]
				"
				replace="
					concat(
						'data:text/plain;charset=utf-8,', 
						encode-for-uri(normalize-space(.))
					)
				"
			/>
			<cx:message name="sanitising-uris" message="Sanitising URIs ..."/>
			<!-- TODO replace step with an XSLT using xsl:analyze-string to tidy the URIs -->
			<p:string-replace name="sanitize-invalid-uri-syntax" 
				match="*[ends-with(local-name(.), '-url')]/text()" 
				replace="replace(., '\\', '%5C')"/>
			<p:string-replace name="sanitize-invalid-uri-syntax-2" 
				match="*[ends-with(local-name(.), '-url')]/text()" 
				replace="replace(., ' ', '%20')"/>
			<p:for-each name="list-of-records">
				<p:iteration-source select="/search/results/result"/><!-- for debugging; select a particular input file [id='35800503']--> 
				<!-- process the item record -->
				<p:variable name="id" select="/result/id"/>
				<p:variable name="graph-uri" select="concat('tag:oceania.digital,2017:', $id)"/>
				<cx:message name="log-attempt">
					<p:with-option name="message" select="concat('ingesting record ', $id, ' as ', $graph-uri, ' ...')"/>
				</cx:message>
				<p:xslt name="transform-digitalnz-result-to-rdf-graph">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="stylesheet">
						<p:document href="../xslt/digitalnz-result-to-rdf.xsl"/>
					</p:input>
				</p:xslt>
				<sparql:store-graph graph-store="http://localhost:8080/fuseki/oceania/data">
					<p:with-option name="graph-uri" select="$graph-uri"/>
				</sparql:store-graph>
				<cx:message name="log-result">
					<p:with-option name="message" select="concat('Result code: ', /c:response/@status)"/>
				</cx:message>
				<p:choose>
					<p:when test="starts-with(/c:response/@status, '2')">
						<!-- 👌 Any kind of 200-level response is good — the graph was created or updated successfully -->
						<p:sink/>
					</p:when>
					<p:otherwise>
						<!-- 
						😣 Some kind of error occurred — we have either:
						‣	a c:response with an unexpected HTTP status code; or 
						‣	a c:error describing a network error
						-->
						<p:store indent="true">
							<p:with-option name="href" select="concat('../../digitalnz-errors/', $id, '.xml')"/>
						</p:store>
					</p:otherwise>
				</p:choose>
			</p:for-each>
		</p:for-each>
	</p:declare-step>
	
</p:declare-step>
