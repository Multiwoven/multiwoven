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
import MWObjectFieldTemplate from "@/views/Connectors/Sources/SourcesForm/SourceConfigForm/MWObjectFieldTemplate";
import MWTitleField from "@/views/Connectors/Sources/SourcesForm/SourceConfigForm/MWTitleField";

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
          {(connectorSchema as any).title.toLowerCase() === "amazon redshift"
            ? <Form
                uiSchema={uiSchema}
                schema={schema as any}
                validator={validator}
                templates={{ObjectFieldTemplate: MWObjectFieldTemplate, TitleFieldTemplate: MWTitleField}}
                onSubmit={({ formData }) => handleFormSubmit(formData)}
              >
                <SourceFormFooter ctaName="Continue" ctaType="submit" />
              </Form>
            : <Form
                schema={connectorSchema}
                validator={validator}
                templates={{ObjectFieldTemplate: MWObjectFieldTemplate}}
                onSubmit={({ formData }) => handleFormSubmit(formData)}
              >
                <SourceFormFooter ctaName="Continue" ctaType="submit" />
              </Form>
          }
        </Box>
      </ContentContainer>
    </Box>
  );
};

const uiSchema = {
  "ui:order": ["host", "port", "database", "credentials", "schema"],
  "ui:layout": {
    display: "grid",
    cols: 2,
    colspans: [2, 1, 1, 2, 2]
  },
  host: {
    "ui:placeholder": "redshift-host.us-east-1.redshift.amazonaws.com",
  },
  credentials: {
    "ui:layout": {
      display: "grid",
      cols: 2,
      colspans: [1, 1]
    },
    auth_type: {
      "ui:widget": "hidden"
    }
  }
}

const schema = {
  $schema: "http://json-schema.org/draft-07/schema#",
  title: "Amazon Redshift",
  type: "object",
  required: ["host", "port", "database", "schema"],
  properties: {
    credentials: {
      title: "",
      type: "object",
      required: ["auth_type", "username", "password"],
      properties: {
        auth_type: {
          type: "string",
          default: "username/password",
          order: 0,
          readOnly: true,
        },
        username: {
          description:
            "Username refers to your individual Redshift login credentials. At a minimum, the user associated with these credentials must be granted read access to the data intended for synchronization.",
          examples: ["REDSHIFT_USER"],
          type: "string",
          title: "Username",
          order: 1,
        },
        password: {
          description:
            "This field requires the password associated with the user account specified in the preceding section.",
          type: "string",
          multiwoven_secret: true,
          title: "Password",
          order: 2,
        },
      },
      order: 0,
    },
    host: {
      description:
        "The hostname or IP address of your Redshift cluster represents a critical connectivity parameter. To retrieve this information, access the Redshift web console, proceed to the Clusters panel, and select your specific cluster. Within the cluster's details, locate and copy the Endpoint string, ensuring to omit the port number and database name appended at the conclusion.",
      examples: [
        "example-redshift-cluster.abcdefg.us-west-2.redshift.amazonaws.com",
      ],
      type: "string",
      title: "Host",
      order: 1,
    },
    port: {
      description:
        "The port number for your Redshift cluster, which defaults to 5439, may vary based on your configuration. To verify the specific port number assigned to your cluster, access the Redshift web console, proceed to the Clusters panel, and select your cluster. You can find the port number displayed within the Properties tab.",
      examples: ["5439"],
      type: "string",
      title: "Port",
      order: 2,
    },
    database: {
      description: "The specific Redshift database to connect to.",
      examples: ["REDSHIFT_DB"],
      type: "string",
      title: "Database",
      order: 3,
    },
    schema: {
      description: "The schema within the Redshift database.",
      examples: ["REDSHIFT_SCHEMA"],
      type: "string",
      title: "Schema",
      order: 4,
    },
  },
}

export default SourceConfigForm;
