#!/bin/bash
# =============================================================================
#  Ambari Cluster Setup Script
#  Author: RAM CH	2026-02-25
#  Usage : /usr/local/bin/setup-cluster.sh
#  Note  : If cluster already exists, delete it first via Ambari UI or API
#         before running this script.
# =============================================================================

echo ""
echo "Step 1: Uploading blueprint..."
curl -s -u admin:admin \
     -H "Content-Type: application/json" \
     -H "X-Requested-By: ambari" \
     -X POST http://localhost:8080/api/v1/blueprints/ambari_cluster \
     -d @/var/lib/ambari-server/resources/blueprint.json
echo ""

echo ""
echo "Step 2: Creating cluster."
curl -s -u admin:admin \
     -H "Content-Type: application/json" \
     -H "X-Requested-By: ambari" \
     -X POST http://localhost:8080/api/v1/clusters/ambari_cluster \
     -d @/var/lib/ambari-server/resources/clustertemplate.json
echo ""

echo ""
echo " You can monitor progress at http://ambari-server:8080/#/main/background-operations"
echo " This will take around 10-30 minutes depending on your container(s) specification...."
echo ""
