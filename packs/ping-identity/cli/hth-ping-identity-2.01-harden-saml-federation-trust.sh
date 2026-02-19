#!/usr/bin/env bash
# HTH Ping Identity Control 2.01: Harden SAML Federation Trust
# Profile: L1 | NIST: IA-5, SC-23
# https://howtoharden.com/guides/ping-identity/#21-harden-saml-federation-trust

# HTH Guide Excerpt: begin saml-config-example
# PingFederate SAML Configuration Example
# XML assertion with short validity window and audience restriction:
#
# <saml:Assertion>
#   <saml:Conditions
#     NotBefore="2025-01-15T10:00:00Z"
#     NotOnOrAfter="2025-01-15T10:05:00Z">
#     <saml:AudienceRestriction>
#       <saml:Audience>https://sp.company.com</saml:Audience>
#     </saml:AudienceRestriction>
#   </saml:Conditions>
# </saml:Assertion>
# HTH Guide Excerpt: end saml-config-example
