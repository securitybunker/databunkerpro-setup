#!/bin/bash

helm lint helm/databunkerpro
helm template test-release helm/databunkerpro
helm package helm/databunkerpro

