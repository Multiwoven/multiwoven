import { useQuery } from "@tanstack/react-query";

import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectorDefinition } from "@/services/connectors";
import { useContext } from "react";
import { Box } from "@chakra-ui/react";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";

import Loader from "@/components/Loader";
import { processFormData } from "@/views/Connectors/helpers";
import ContentContainer from "@/components/ContentContainer";
import ObjectFieldTemplate from "@/views/Connectors/Sources/SourcesForm/SourceConfigForm/CustomObjectFieldTemplate";

const SourceConfigForm = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const selectedDataSource = forms.find(
    ({ stepKey }) => stepKey === "datasource"
  );
  const datasource = selectedDataSource?.data?.datasource as string;

  if (!datasource) return null;

  const { data, isLoading } = useQuery({
    queryKey: ["connector_definition", datasource],
    queryFn: () => getConnectorDefinition("source", datasource),
    enabled: !!datasource,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  if (isLoading) return <Loader />;

  const handleFormSubmit = async (formData: FormData) => {
    const processedFormData = processFormData(formData);
    handleMoveForward(stepInfo?.formKey as string, processedFormData);
  };

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;
  return (
    <Box display="flex" justifyContent="center" marginBottom="80px">
      <ContentContainer>
        <Box backgroundColor="gray.200" padding="20px" borderRadius="8px">
          <Form
            schema={connectorSchema}
            validator={validator}
            templates={{ObjectFieldTemplate: ObjectFieldTemplate}}
            onSubmit={({ formData }) => handleFormSubmit(formData)}
          >
            <SourceFormFooter ctaName="Continue" ctaType="submit" />
          </Form>
        </Box>
      </ContentContainer>
    </Box>
  );
};

/**

{
	"connection_specification": {
		"$schema": "http://json-schema.org/draft-07/schema#",
		"title": "Snowflake",
		"type": "object",
		"required": [
			"host",
			"role",
			"warehouse",
			"database"
		],
		"properties": {
			"credentials": {
				"title": "",
				"type": "object",
				"required": [
					"auth_type",
					"username",
					"password"
				],
				"properties": {
					"auth_type": {
						"type": "string",
						"default": "username/password",
						"order": 0,
						"readOnly": true
					},
					"username": {
						"description": "The username you created to allow multiwoven to access the database.",
						"examples": [
							"MULTIWOVEN_USER"
						],
						"type": "string",
						"title": "Username",
						"order": 1
					},
					"password": {
						"description": "The password associated with the username.",
						"type": "string",
						"multiwoven_secret": true,
						"title": "Password",
						"order": 2
					}
				},
				"order": 0
			},
			"host": {
				"description": "The host domain of the snowflake instance (must include the account, region, cloud environment, and end with snowflakecomputing.com).",
				"examples": [
					"accountname.us-east-2.aws.snowflakecomputing.com"
				],
				"type": "string",
				"title": "Account Name",
				"order": 1
			},
			"role": {
				"description": "The role you created for multiwoven to access Snowflake.",
				"examples": [
					"MULTIWOVEN_ROLE"
				],
				"type": "string",
				"title": "Role",
				"order": 2
			},
			"warehouse": {
				"description": "The warehouse you created for multiwoven to access data.",
				"examples": [
					"MULTIWOVEN_WAREHOUSE"
				],
				"type": "string",
				"title": "Warehouse",
				"order": 3
			},
			"database": {
				"description": "The database you created for multiwoven to access data.",
				"examples": [
					"MULTIWOVEN_DATABASE"
				],
				"type": "string",
				"title": "Database",
				"order": 4
			},
			"schema": {
				"description": "The source Snowflake schema tables. Leave empty to access tables from multiple schemas.",
				"examples": [
					"MULTIWOVEN_SCHEMA"
				],
				"type": "string",
				"title": "Schema",
				"order": 5
			},
			"jdbc_url_params": {
				"description": "Additional properties to pass to the JDBC URL string when connecting to the database formatted as 'key=value' pairs separated by the symbol '&'. (example: key1=value1&key2=value2&key3=value3).",
				"title": "JDBC URL Params",
				"type": "string",
				"order": 6
			}
		}
	}
}
 */

export default SourceConfigForm;
