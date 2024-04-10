# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2024-04-08

### 🚀 Features

- Add Filtering by Connector Type to 'Get All Connectors' API
- Add batch support for rETL
- Add default scope for Connector, Model and Sync
- Strong type validation for API
- Enhance DestinationSelector and Source and changed Dashboard UI
- Implemented delete sync
- Start with default custom object template from chakra package
- Try simple layouting
- Add support for specifying colspans
- Add title field for overriding titles in form
- Use overridden title field instead of default one
- Add BaseInputTemplate
- Add title field template
- Add title to all the meta json in all connector
- Add postgresql connector
- Rate limiting
- Configure rate limit for destinations
- Add hubspot destination connector
- Add databricks source connector
- Reporting dashboard api
- Standardization of output
- Implement static, variable and template catalog field mapping
- Enable rate limiting
- Add finite state machine for sync states
- Sync run and sync record controller
- Terminate workflow on sync deletion
- Delete source
- Edit destinations screen and delete destinations
- Add pull request template
- Add env example file
- Configure retry policy for terminate workflows
- Add databricks odbc driver
- Sync run api by sync id
- Support full refresh sync
- Custom liquid helper to_datetime
- Sync mode changes for destination connectors
- Destination/google sheets
- *(destination)* Add airtable
- *(destination)* Add Stripe destination connector
- Support full refresh sync
- Add Salesforce Consumer Goods destination connector
- Add Salesforce Consumer Goods source connector 
- Add postgresql destination connector
- Release process automation 
- Move integrations gem github actions to root
- Move server and ui github action ci to root
- Added sync records
- Add soql support query_type
- Update salesforce consumer goods authentication
- Flatten salesforce records attributes
- Add connector images to github to serve icons
- Adding batch_support flag and batch_size in catalog for sync
- Add batch support for facebook custom audience connector 
- The volume mount paths don't clash with existing volumes and .env file added
- Create sync run when pending sync run is absent
- Duplicate sync record with primary key

### 🐛 Bug Fixes

- Snowflake odbc
- Increment sync run offsets after each batch query
- Model preview queries
- IncrementalDelta primary key downcase issue
- Input background not white when put in not white containers
- Add empty line at the end
- Add types for connector schema response from backend
- Persist configure screen data on navigation
- Edit syncs dropdown values
- Conditionally render footer elements in create sync
- Pre-render components during edit sync
- Redirect routes for adding models and connectors
- Footer buttons missing in source config form
- Spinner style mismatch
- Updated edit model header to include breadcrumbs
- Added breadcrumbs and ui fix in edit query screen
- Multiple mapping bug during create sync
- Update chakra theme with design system font tokens
- Design mismatch between form component and design
- Spacing issues between the input and label
- Style mismatch of description in source config form
- Clicking on add source goes to destinations
- Description spanning fully by adding a max width
- Add connector button hardcoded to navigate to sources page always
- Update text for no connectors found
- Add batch params to stream
- Release github action to use official gem action
- Slack and salesforce svg
- Avoid numbers in path created by gem in server
- Change keytransform from underscore to unaltered
- Update link to resources in readme
- Prevent sync without connector
- Bypass cc-test-reporter steps
- Return complete slices in reporting
- Update condition for domain name
- Update issues link in the readme
- Handle error during listing sync
- Docker file env update for api host
- Soft delete for sync run
- Password policy
- Pagination link invalid
- Update login timeout
- Handle nil for to_datetime filter in liquid
- Databricks connector specification
- Spec password 
- Update query and create connection
- Sftp server integration
- Schema_mode changes to enum
- Sftp full refresh
- Add batch support fields in catalog streams
- Batch size in salesforce consumer goods cloud
- Destination path fix in check connection
- Sftp connection spec filename added
- Build and lint errors
- Lint and build errors
- Add primary key validation for extractor

### 🚜 Refactor

- Heartbeat timeout for loader and extractor activity
- Remove unwanted code added for debugging
- Change ui schemas to an object so that it only gets applied on pages where the ui schema is to be used
- Extract query method for model preview
- Support multiple connectors in reporting
- Minor changes
- Moved tab filters to new component

### 📚 Documentation

- Add comments to explain layout schema
- Add github template for multiwoven server
- Update readme for ui
- Update readme link for contribution guideline
- Update contribution guidelines

### 🎨 Styling

- Fix the exit modal as per designs
- Update styling for step 1 for syncs page
- Update the brand color in chakra config
- Fix the designs of the top bar and model list table
- Update table coloumns styling
- Update styles for step 3 in syncs page
- Fix the alignment of the footer container
- Fix footer button alignments
- Update styling for finale sync page
- Update heading text
- Update the color to use from tokens
- Fix weaving soon design
- Ui improvements for edit sync page
- Make status tag consistent
- Update styling for edit model details modal
- Update edit model modal buttons
- Update styling for delete modal
- Update styling for final model submit step
- Update background color for syncs page
- Update bg color for the list screens
- Update all destinations pill
- Update connect your destination form styling
- Update test destination screen
- Fix the padding of table
- Update background colors for edit sync box
- Update padding of the box
- Update the font size
- Update the border color for disabled state
- Update designs for selecting data source
- Update style for testing source screen
- Update design for final source step
- Update top bar for edit source
- Update form design for edit source
- Update side nav as per figma
- Update styling for logout modal
- Align the breadcrumbs on top bar
- Update copy changes for syncs screen
- Update copy changes for models
- Update copy for destinations screen

<!-- generated by git-cliff -->
