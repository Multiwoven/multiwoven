import { useEffect, useState } from "react";
import { Formik, Form, ErrorMessage } from "formik";
import * as Yup from "yup";
import {
	Button,
	Container,
	FormControl,
	FormHelperText,
	FormLabel,
	Input,
	VStack,
} from "@chakra-ui/react";
import { useLocation } from "react-router-dom";
import { getConnectorDefinition } from "@/services/common";

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
}

export const ConnectorConfig = ({ connectorType }: ConnectorConfigProps) => {
	const [connector, setConnector] = useState<Connector | null>(null);
	const location = useLocation();

	const queryParams = new URLSearchParams(location.search);
	const type = queryParams.get("type") || "";
	const name = queryParams.get("name") || "";

	useEffect(() => {
		async function fetchData() {
			// const adjustedConnectorType = connectorType === "sources" ? "source" : "destination";
			const response = await getConnectorDefinition(type, name);
			setConnector(response?.data);
		}

		fetchData();
	}, [connectorType, type, name]);

	const connectorSpec = connector?.connector_spec.connection_specification;

	// Creating a Yup schema dynamically based on the JSON
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

	// Initial form values
	const initialValues = connectorSpec?.properties
		? Object.keys(connectorSpec.properties).reduce((values, key) => {
				values[key] = "";
				return values;
		  }, {} as { [key: string]: string })
		: {};

	return (
		<Formik
			initialValues={initialValues}
			validationSchema={validationSchema}
			onSubmit={(values) => {
				console.log(values);
			}}
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
											<Input
												id={key}
												type='text'
												{...getFieldProps(key)} 
											/>
											<ErrorMessage name={key} component='div' />
											{field.description && (
												<FormHelperText w="md">{field.description}</FormHelperText>
											)}
										</FormControl>
									);
								})}
							<Button type='submit' colorScheme='blue'>
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
