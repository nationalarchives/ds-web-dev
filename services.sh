#!/bin/bash

# Define the list of services - these are the names of the repositories in the nationalarchives GitHub organisation
# shellcheck disable=SC2034
declare -a services=(
    "ds-bulk-download"
    "ds-catalogue"
    "ds-forms"
    "ds-frontend"
    "ds-frontend-enrichment"
    "ds-hospital-records"
    "ds-request-service-record"
    "ds-service-status"
    "ds-sitemap-search"
    "ds-wagtail"
    "wa-frontend"
)
declare -a services_with_tna_frontend=(
    "ds-bulk-download"
    "ds-catalogue"
    "ds-forms"
    "ds-frontend"
    "ds-frontend-enrichment"
    "ds-hospital-records"
    "ds-request-service-record"
    "ds-service-status"
    "ds-sitemap-search"
    "wa-frontend"
)
# Services that depend on the Wagtail API key - these are the services that have a .env file with the WAGTAIL_API_KEY variable
declare -a wagtail_dependant_services=(
    "services/ds-catalogue"
    "services/ds-frontend"
    "services/wa-frontend"
    "."
)
