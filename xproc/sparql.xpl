<?xml version="1.0"?>
<!--
   Copyright 2016 Conal Tuohy

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
<p:library 
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:sparql="tag:conaltuohy.com,2017:sparql"
	xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>	
	
	<p:declare-step type="sparql:update" name="sparql-update">
		<p:option name="service-uri"/>
		<p:option name="query"/>
		<p:template name="construct-deletion-request">
			<p:with-param name="service-uri" select="$service-uri"/>
			<p:with-param name="query" select="$query"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<c:request href="{$service-uri}" method="POST" detailed="true">
						<c:body content-type="application/sparql-update">{$query}</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request name="sparql-update-http-post"/>
		<p:sink/>
	</p:declare-step>
	
	<!-- delete graph -->
	<p:declare-step type="sparql:delete-graph" name="delete-graph">
		<p:option name="graph-store" required="true"/>
		<p:option name="graph-uri" required="true"/>
		<p:template name="construct-deletion-request">
			<p:with-param name="graph-store" select="$graph-store"/>
			<p:with-param name="graph-uri" select="$graph-uri"/>
			<p:input port="template">
				<p:inline>
					<c:request method="DELETE" href="{$graph-store}{$graph-uri}" detailed="true"/>
				</p:inline>
			</p:input>
			<p:input port="source">
				<p:empty/>
			</p:input>
		</p:template>
		<p:http-request/>
		<p:sink/>
	</p:declare-step>
	
	<!-- store graph -->
	<p:declare-step type="sparql:store-graph" name="store-graph">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="graph-store" required="true"/>
		<p:option name="graph-uri" required="true"/>
		<!-- execute an HTTP PUT to store the graph in the graph store at the location specified -->
		<p:template name="generate-put-request">
			<p:with-param name="graph-store" select="$graph-store"/>
			<p:with-param name="graph-uri" select="$graph-uri"/>
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			  </p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="PUT" href="{$graph-store}?graph={encode-for-uri($graph-uri)}" detailed="true">
						<c:body content-type="application/rdf+xml">{ /* }</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:try name="submit-request">
			<p:group>
				<p:http-request/>
			</p:group>
			<p:catch name="http-connection-failed">
				<p:identity>
					<p:input port="source">
						<p:pipe step="http-connection-failed" port="error"/>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>
	</p:declare-step>
	
</p:library>
