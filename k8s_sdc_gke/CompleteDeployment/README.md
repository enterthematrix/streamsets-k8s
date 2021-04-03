<img src="/images/readme.png" align="right" />

# Automated script to launch a GKE cluster with SDC

This script automates creating a GKE cluster with SDC (with all the stage libs)

## Pre-req:

1) Google CLI -- https://cloud.google.com/sdk/docs/quickstart
2) kubectl (brew install kubectl )
3) jq (brew install jq)
4) helm (brew install helm)

## Optional (recommended)

For minimal interaction with the script, you should set the following environment variables:

SCH_URL (default: https://cloud.streamsets.com)
SCH_ORG (default: dpmsupport)
SCH_USER (Your SCH user) ** Please note: https://streamsets.com/documentation/controlhub/latest/help/controlhub/UserGuide/OrganizationSecurity/Authentication.html#concept_nmk_zh3_11b
SCH_PASSWORD (Your SCH password)
SDC_DOWNLOAD_USER (default: StreamSets)
SDC_DOWNLOAD_PASSWORD - Get the latest password @ https://support.streamsets.com/hc/en-us/articles/360046575233-StreamSets-Data-Collector-and-Transformer-Binaries-Download
INSTALL_TYPE (default: b(basic), specify f for all the stage libraries)
