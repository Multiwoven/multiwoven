## [0.106.0] - 2026-03-20

### 🚀 Features

- *(CE)* Add semistructured model query type (#897)
- *(CE)* Refactor google drive source connector (#895)

### 🐛 Bug Fixes

- *(CE)* Change AWS Bedrock sub category (#889)
- *(CE)* Handles error when downloading file from drive with backslashes (#901)
- *(CE)* Next_page_token not cleared, messing with call to get file (#899)
- *(CE)* Abstract field not available in model in some odoo versions (#972)

### ⚙️ Miscellaneous Tasks

- *(CE)* Refactor PostgreSQL Destination Connector (#903)
- *(CE)* Filter changes for vector db connectors (#907)
- *(CE)* Enhance S3 Connector to support custom endpoints for MinIO (#936)
- *(CE)* Remove schemaless catalog from Amazon S3 Connector (#940)
- *(CE)* Add URL_STYLE 'path' to secret_part in S3 (#939)
