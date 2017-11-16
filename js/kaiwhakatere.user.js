// ==UserScript==
// @name         Kaiwhakatere (Navigator)
// @namespace    http://oceania.digital/
// @version      0.1
// @description  Looks up links in Oceania, displays associated metadata
// @author       Conal Tuohy (@conal_tuohy)
// @match        https://oceania-digital.tumblr.com/*
// @match        http://nzetc.victoria.ac.nz/*
// @match        https://teara.govt.nz/*
// @match        http://www.aucklandmuseum.com/*
// @match        http://ketechristchurch.peoplesnetworknz.info/*
// @match        https://en.wikipedia.org/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
	var httpRequest;

	var logEnabled = true;
	function log(label, data) {
		if (logEnabled) {
			console.log("\n" + label);
			console.log(data);
		}
		return data;
	}

	function processGraph(trix) {
		log("processing linked data graph", trix);
		// use the graph (in Trix format) to decorate the page
		var oceaniaLinks = evaluateXPath(document, ".//*[@data-oceania-uri]");
		// decorate each of the links in the page with data from the graph
		oceaniaLinks
			.map(link => log("decorating link", link))
			.forEach(
				function(link) {
					// Decorate the HTML hyperlink with corresponding data taken from the graph.
					// The 'subject' is the node which has the original web page hyperlink as one of its objects (i.e. it represents a digitalNZ metadata record)
					var subject = evaluateXPath(trix, "//trix:triple[trix:uri[3]='" + link.dataset.oceaniaUri + "']/trix:uri[1]")[0];
					if (subject) {
						// the link in the web page was found in the rdf graph
						// set the title of the hyperlink to the value of the digitalNZ "description" property
						evaluateXPath(trix, "//trix:triple[trix:uri[1]='" + subject.textContent + "'][trix:uri[2]='tag:oceania.digital,2017:digitalnz#description']/*[3]")
							.forEach(title => link.title = title.textContent);
						log("decorated link", link);
					}
				}
			);


	}

	function receiveResponse() {
		try {
			if (httpRequest.readyState === XMLHttpRequest.DONE) {
				if (httpRequest.status === 200) {
					processGraph(httpRequest.responseXML);
				} else {
					console.log('\nReceived ' + httpRequest.status + ' error from oceania.digital server');
					console.log(httpRequest.responseText);
				}
			}
		}
		catch( e ) {
			console.log('\nFailed to read response from oceania.digital server');
			console.log(e);
		}
	}

	// evaluate an XPath relative to the provided context, result is an array of Node objects
	function evaluateXPath(context, xpath) {
		var nsResolver = function (prefix) {
			var ns = {
				'trix' : 'http://www.w3.org/2004/03/trix/trix-1/'
			};
			return ns[prefix] || null;
		};
		var doc = context.nodeType == Node.DOCUMENT_NODE ? context : context.ownerDocument;
		var nodeset = doc.evaluate(
			xpath, context, nsResolver, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null
		);
		return Array(nodeset.snapshotLength)
			.fill(0)
			.map(
				function(element, index) {
					return nodeset.snapshotItem(index);
				}
			);
	}

	// extracts URI parameters from the "search" string and returns an array of those which begin with "http" and are probably URIs
	function getEncodedUriParameters(search) {
		return Array.from(new URLSearchParams(search).values())
			.filter(parameter => parameter.startsWith('http')); // starts with http so it's probably a URI;
	}

	// decorates a hyperlink element with a normalized version of the element's own href attribute, to later look up in oceania.digital
	function setOceaniaUri(link) {
		var encodedURIs = getEncodedUriParameters(link.search) // the URIs that are encoded as search parameters in this URI
			.filter(url => ! url.startsWith(document.origin)); // only URIs which point to a different site to this one (could be a redirection target)
		if (encodedURIs.length > 0) {
			link.dataset.oceaniaUri = encodedURIs[0]; // save the first outward-pointing URI parameter
		} else { // no "redirection URL" parameters extracted from URL, so try the full URL itself
			// filter out local and non-http links and links which still contain embedded URI parameters since likely to not be interesting
			//if (! link.href.startsWith(document.origin) && link.href.startsWith('http') && getEncodedUriParameters(link.search).length === 0) {

			if (link.href.startsWith('http') &&
				getEncodedUriParameters(link.search).length === 0 &&
				link.origin != document.origin
			   ) {
				link.dataset.oceaniaUri = link.href.split('#')[0];
			}
		}
	}

    // construct query, retrieve data, generate UI
	evaluateXPath(document, '//a[@href]')
		.forEach(link => setOceaniaUri(link));

	// having populated the DOM with @data-oceania-uri attributes, now query the RDF and connect the resulting graph back to the DOM
	var oceaniaLinks = evaluateXPath(document, ".//*[@data-oceania-uri]");
	if (oceaniaLinks.length > 0) {
		var query =
			"CONSTRUCT {?s ?pAny ?oAny}\nWHERE {\n\t?s ?p ?o.\n\t?s ?pAny ?oAny\n\tFILTER(?o IN (" +
			oceaniaLinks.map(link => "\n\t\t<" + link.dataset.oceaniaUri + ">") +
			"\n\t))\n}";
		log("sending SPARQL query to oceania.digital", query);
		httpRequest = new XMLHttpRequest();
		httpRequest.onreadystatechange = receiveResponse;
		httpRequest.open('GET', 'https://oceania.digital/fuseki/oceania/query?query=' + encodeURIComponent(query), true);
		httpRequest.setRequestHeader('Accept', 'application/trix+xml');
		httpRequest.send(query);
	}
})();
