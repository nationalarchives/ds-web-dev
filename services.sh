#!/bin/bash

# Define the list of services - these are the names of the repositories in the nationalarchives GitHub organisation
declare -a services=(
    "ds-frontend"
    "ds-wagtail"
    "ds-catalogue"
    "ds-frontend-enrichment"
    "ds-sitemap-search"
    "ds-request-service-record"
    "ds-service-status"
)
