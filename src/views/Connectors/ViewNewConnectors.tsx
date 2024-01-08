import TopBar from "@/components/TopBar";
import { getConnectorsDefintions } from "@/services/common";
import { Box, Flex, Image, SimpleGrid } from "@chakra-ui/react";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

const sampleConnectorsSpecs = [
  {
    name: "Snowflake",
    connector_type: "source",
    connector_subtype: "database",
    documentation_url: "https://docs.mutliwoven.com",
    github_issue_label: "source-snowflake",
    icon: "snowflake.svg",
    license: "MIT",
    release_stage: "alpha",
    support_level: "community",
    tags: ["language:ruby", "multiwoven"],
    connector_spec: {
      documentation_url:
        "https://docs.multiwoven.com/integrations/sources/snowflake",
      connection_specification: {
        $schema: "http://json-schema.org/draft-07/schema#",
        title: "Snowflake Source Spec",
        type: "object",
        required: ["host", "role", "warehouse", "database"],
        properties: {
          credentials: {
            title: "Authorization Method",
            type: "object",
            oneOf: [
              {
                title: "Username and Password",
                type: "object",
                required: ["username", "password", "auth_type"],
                order: 1,
                properties: {
                  auth_type: {
                    type: "string",
                    const: "username/password",
                    order: 0,
                  },
                  username: {
                    description:
                      "The username you created to allow multiwoven to access the database.",
                    examples: ["MULTIWOVEN_USER"],
                    type: "string",
                    title: "Username",
                    order: 1,
                  },
                  password: {
                    description: "The password associated with the username.",
                    type: "string",
                    multiwoven_secret: true,
                    title: "Password",
                    order: 2,
                  },
                },
              },
            ],
            order: 0,
          },
          host: {
            description:
              "The host domain of the snowflake instance (must include the account, region, cloud environment, and end with snowflakecomputing.com).",
            examples: ["accountname.us-east-2.aws.snowflakecomputing.com"],
            type: "string",
            title: "Account Name",
            order: 1,
          },
          role: {
            description:
              "The role you created for multiwoven to access Snowflake.",
            examples: ["MULTIWOVEN_ROLE"],
            type: "string",
            title: "Role",
            order: 2,
          },
          warehouse: {
            description:
              "The warehouse you created for multiwoven to access data.",
            examples: ["MULTIWOVEN_WAREHOUSE"],
            type: "string",
            title: "Warehouse",
            order: 3,
          },
          database: {
            description:
              "The database you created for multiwoven to access data.",
            examples: ["MULTIWOVEN_DATABASE"],
            type: "string",
            title: "Database",
            order: 4,
          },
          schema: {
            description:
              "The source Snowflake schema tables. Leave empty to access tables from multiple schemas.",
            examples: ["MULTIWOVEN_SCHEMA"],
            type: "string",
            title: "Schema",
            order: 5,
          },
          jdbc_url_params: {
            description:
              "Additional properties to pass to the JDBC URL string when connecting to the database formatted as 'key=value' pairs separated by the symbol '&'. (example: key1=value1&key2=value2&key3=value3).",
            title: "JDBC URL Params",
            type: "string",
            order: 6,
          },
        },
      },
      supports_normalization: false,
      supports_dbt: false,
      stream_type: "dynamic",
    },
  },
  {
    name: "Redshift",
    connector_type: "source",
    connector_subtype: "database",
    documentation_url: "https://docs.mutliwoven.com",
    github_issue_label: "source-redshift",
    icon: "redshift.svg",
    license: "MIT",
    release_stage: "alpha",
    support_level: "community",
    tags: ["language:ruby", "multiwoven"],
    connector_spec: {
      documentation_url:
        "https://docs.multiwoven.com/integrations/sources/redshift",
      connection_specification: {
        $schema: "http://json-schema.org/draft-07/schema#",
        title: "Redshift Source Spec",
        type: "object",
        required: ["host", "port", "database", "schema"],
        properties: {
          credentials: {
            title: "Authorization Method",
            type: "object",
            oneOf: [
              {
                title: "Username and Password",
                type: "object",
                required: ["username", "password", "auth_type"],
                order: 1,
                properties: {
                  auth_type: {
                    type: "string",
                    const: "username/password",
                    order: 0,
                  },
                  username: {
                    description: "The username for Redshift database access.",
                    examples: ["REDSHIFT_USER"],
                    type: "string",
                    title: "Username",
                    order: 1,
                  },
                  password: {
                    description: "The password for the Redshift user.",
                    type: "string",
                    multiwoven_secret: true,
                    title: "Password",
                    order: 2,
                  },
                },
              },
            ],
            order: 0,
          },
          host: {
            description: "The host endpoint of the Redshift cluster.",
            examples: [
              "example-redshift-cluster.abcdefg.us-west-2.redshift.amazonaws.com",
            ],
            type: "string",
            title: "Host",
            order: 1,
          },
          port: {
            description:
              "The port on which Redshift is running (default is 5439).",
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
      },
      supports_normalization: false,
      supports_dbt: false,
      stream_type: "dynamic",
    },
  },
  {
    name: "BigQuery",
    connector_type: "source",
    connector_subtype: "database",
    documentation_url: "https://docs.mutliwoven.com",
    github_issue_label: "source-bigquery",
    icon: "bigquery.svg",
    license: "MIT",
    release_stage: "alpha",
    support_level: "community",
    tags: ["language:ruby", "multiwoven"],
    connector_spec: {
      documentation_url:
        "https://docs.multiwoven.com/integrations/sources/bigquery",
      connection_specification: {
        $schema: "http://json-schema.org/draft-07/schema#",
        title: "BigQuery Source Spec",
        type: "object",
        required: ["project_id", "credentials_json"],
        properties: {
          project_id: {
            type: "string",
            description:
              "The GCP project ID for the project containing the target BigQuery dataset.",
            title: "Project ID",
          },
          dataset_id: {
            type: "string",
            description:
              "The dataset ID to search for tables and views. If you are only loading data from one dataset, setting this option could result in much faster schema discovery.",
            title: "Default Dataset ID",
          },
          credentials_json: {
            type: "string",
            description:
              'The contents of your Service Account Key JSON file. See the <a href="https://docs.multiwoven.com/integrations/sources/bigquery#setup-the-bigquery-source-in-multiwoven">docs</a> for more information on how to obtain this key.',
            title: "Credentials JSON",
            multiwoven_secret: true,
          },
        },
      },
      supports_normalization: false,
      supports_dbt: false,
      stream_type: "dynamic",
    },
  },
  {
    name: "BigQuery",
    connector_type: "source",
    connector_subtype: "database",
    documentation_url: "https://docs.mutliwoven.com",
    github_issue_label: "source-bigquery",
    icon: "bigquery.svg",
    license: "MIT",
    release_stage: "alpha",
    support_level: "community",
    tags: ["language:ruby", "multiwoven"],
    connector_spec: {
      documentation_url:
        "https://docs.multiwoven.com/integrations/sources/bigquery",
      connection_specification: {
        $schema: "http://json-schema.org/draft-07/schema#",
        title: "BigQuery Source Spec",
        type: "object",
        required: ["project_id", "credentials_json"],
        properties: {
          project_id: {
            type: "string",
            description:
              "The GCP project ID for the project containing the target BigQuery dataset.",
            title: "Project ID",
          },
          dataset_id: {
            type: "string",
            description:
              "The dataset ID to search for tables and views. If you are only loading data from one dataset, setting this option could result in much faster schema discovery.",
            title: "Default Dataset ID",
          },
          credentials_json: {
            type: "string",
            description:
              'The contents of your Service Account Key JSON file. See the <a href="https://docs.multiwoven.com/integrations/sources/bigquery#setup-the-bigquery-source-in-multiwoven">docs</a> for more information on how to obtain this key.',
            title: "Credentials JSON",
            multiwoven_secret: true,
          },
        },
      },
      supports_normalization: false,
      supports_dbt: false,
      stream_type: "dynamic",
    },
  },
  {
    name: "BigQuery",
    connector_type: "source",
    connector_subtype: "database",
    documentation_url: "https://docs.mutliwoven.com",
    github_issue_label: "source-bigquery",
    icon: "bigquery.svg",
    license: "MIT",
    release_stage: "alpha",
    support_level: "community",
    tags: ["language:ruby", "multiwoven"],
    connector_spec: {
      documentation_url:
        "https://docs.multiwoven.com/integrations/sources/bigquery",
      connection_specification: {
        $schema: "http://json-schema.org/draft-07/schema#",
        title: "BigQuery Source Spec",
        type: "object",
        required: ["project_id", "credentials_json"],
        properties: {
          project_id: {
            type: "string",
            description:
              "The GCP project ID for the project containing the target BigQuery dataset.",
            title: "Project ID",
          },
          dataset_id: {
            type: "string",
            description:
              "The dataset ID to search for tables and views. If you are only loading data from one dataset, setting this option could result in much faster schema discovery.",
            title: "Default Dataset ID",
          },
          credentials_json: {
            type: "string",
            description:
              'The contents of your Service Account Key JSON file. See the <a href="https://docs.multiwoven.com/integrations/sources/bigquery#setup-the-bigquery-source-in-multiwoven">docs</a> for more information on how to obtain this key.',
            title: "Credentials JSON",
            multiwoven_secret: true,
          },
        },
      },
      supports_normalization: false,
      supports_dbt: false,
      stream_type: "dynamic",
    },
  },
];

export const ViewNewConnectors = (props: any) => {
  const [connectorsSpecs, setConnectorsSpecs] = useState<Array<any>>([]);
  // console.log(props.connectorType);

  useEffect(() => {
    async function fetchData() {
      const connectorType = props.connectorType === "sources" ? "source" : "destination";
      console.log(props.connectorType,connectorType);
      
      const response = await getConnectorsDefintions(connectorType);
      console.log(response);
      setConnectorsSpecs(response?.data);
      // setConnectorsSpecs(sampleConnectorsSpecs);
    }

    fetchData();
  }, []);

  if (!connectorsSpecs) {
    return <>LOADING</>;
  }

  return (
    <Box
      display="flex"
      width="full"
      margin={8}
      flexDir="column"
      backgroundColor={""}
    >
      <Box padding="8" bgColor={""}>
        {/* <h1>{ props.connectorType }s</h1> */}
        <TopBar
          connectorType={props.connectorType}
          buttonText={props.connectorType}
          buttonOnClick={() => console.log("new")}
        />
        <SimpleGrid columns={3} spacing={4}>
          {connectorsSpecs.map((item, index) => (
            <Link to={"config?type=" + "source" + "&name=" + item.name.toLowerCase()} key={index}>
            <Box bgColor="gray.100" _hover={{bgColor:"gray.200"}} shadow="sm" p={5} borderRadius={12}>
              <Flex dir="row" justifyContent="left" justifyItems="left">
                <Image
                  src={"/icons/" + item.icon}
                  // alt={`${item.name} Icon`}
                  height="8"
                  w="min"
                  mr={3}
                />
                <h1>{item.name}</h1>
              </Flex>
            </Box>
            </Link>
          ))}
        </SimpleGrid>
      </Box>
    </Box>
  );
};
