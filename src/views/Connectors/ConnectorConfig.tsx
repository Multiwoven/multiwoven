import { useEffect, useState } from "react";
import { Formik, Form, ErrorMessage } from "formik";
import * as Yup from "yup";
import {
  Button,
  FormControl,
  FormHelperText,
  FormLabel,
  Input,
  VStack,
} from "@chakra-ui/react";
import { useLocation, useParams } from "react-router-dom";
import { getConnectorData, getConnectorDefinition } from "@/services/common";

interface ConnectorSpecProperty {
  title?: string;
  description?: string;
}

interface ConnectorSpec {
  properties: {
    [key: string]: ConnectorSpecProperty;
  };
  required: string[];
}

interface Connector {
  connector_spec: {
    connection_specification: ConnectorSpec;
  };
}

interface ConnectorConfigProps {
  connectorType: string;
  configValues?: boolean;
}

interface FormValues {
  [key: string]: any; // Define a type for dynamic form values
}

export const ConnectorConfig = ({
  connectorType,
  configValues,
}: ConnectorConfigProps) => {
  const [connector, setConnector] = useState<Connector | null>(null);
  const [initialFormValues, setInitialFormValues] = useState<FormValues>({}); // Use FormValues type
  const location = useLocation();

  const queryParams = new URLSearchParams(location.search);
  const params = useParams();

  const id = params?.id;
  const type = queryParams.get("type") || "";
  const name = queryParams.get("name") || "";

  useEffect(() => {
    async function fetchData() {
      // const adjustedConnectorType = connectorType === "sources" ? "source" : "destination";
      const response = await getConnectorDefinition(type, name);
      setConnector(response?.response.data);
    }

    async function getFormPrefillData() {
      const prefillData = await getConnectorData(id || "");
      // setInitialFormValues(prefillData?.data);
      return prefillData;
    }

    if (configValues && id !== undefined) {
      getFormPrefillData().then((response) =>
        setInitialFormValues(response.data)
      );
      console.log(initialFormValues);
    }

    fetchData();
  }, [connectorType, type, name]);

  const connectorSpec = connector?.connector_spec.connection_specification;

  const validationSchema = Yup.object(
    connectorSpec?.properties
      ? Object.keys(connectorSpec.properties).reduce((schema, key) => {
          schema[key] = connectorSpec.required.includes(key)
            ? Yup.string().required("Required")
            : Yup.string();
          return schema;
        }, {} as { [key: string]: Yup.StringSchema })
      : {}
  );

  const createInitialFormValues = (spec: ConnectorSpec | undefined) => {
    const initialValues: FormValues = {};
    if (spec?.properties) {
      Object.keys(spec.properties).forEach((key) => {
        initialValues[key] = ""; // Set each field to an empty string initially
      });
    }
    return initialValues;
  };

  // Create initial values based on connectorSpec properties
  const defaultInitialValues = createInitialFormValues(connectorSpec);

  const formInitialValues =
    Object.keys(initialFormValues).length > 0
      ? initialFormValues
      : defaultInitialValues;

  console.log(formInitialValues, connectorSpec?.properties);

  return (
    <Formik
      initialValues={formInitialValues}
      validationSchema={validationSchema}
      onSubmit={(values) => {
        console.log(values);
      }}
      enableReinitialize
    >
      {({ getFieldProps, touched, errors }) => (
        <Form>
          <>
            <VStack spacing={4}>
              {connectorSpec &&
                Object.keys(connectorSpec.properties).map((key, index) => {
                  const field = connectorSpec.properties[key];
                  return (
                    <FormControl
                      key={index}
                      isInvalid={!!(touched[key] && errors[key])}
                      isRequired={connectorSpec.required.includes(key)}
                    >
                      <FormLabel htmlFor={key}>{field.title || key}</FormLabel>
                      <Input id={key} type="text" {...getFieldProps(key)} />
                      <ErrorMessage name={key} component="div" />
                      {field.description && (
                        <FormHelperText w="md">
                          {field.description}
                        </FormHelperText>
                      )}
                    </FormControl>
                  );
                })}
              <Button type="submit" colorScheme="blue">
                Submit
              </Button>
            </VStack>
          </>
        </Form>
      )}
    </Formik>
  );
};

export default ConnectorConfig;
