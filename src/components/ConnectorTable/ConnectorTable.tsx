import {
	Table,
	Thead,
	Tbody,
	Tr,
	Th,
	Td,
	TableContainer,
	Image,
	Flex,
	Text,
	Badge,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";

const samplePayload : Payload[] = [
      {
          "id": "1",
          "type": "connectors",
          "connector_name": "Snowflake",
          "icon": "snowflake.svg",
          "attributes": {
              "name": "Sample connector",
              "connector_type": "source",
              "workspace_id": 8,
              "created_at": "2024-01-08T13:38:45.388Z",
              "updated_at": "2024-01-08T13:38:45.388Z",
              "configuration": {
                  "host": "exampleaccount.us-west-2.aws.snowflakecomputing.com",
                  "role": "ExampleRole",
                  "schema": "ExampleSchema",
                  "database": "ExampleDatabase",
                  "warehouse": "ExampleWarehouse",
                  "credentials": {
                      "password": "example_password",
                      "username": "example_user",
                      "auth_type": "username/password"
                  },
                  "jdbc_url_params": "param1=value1&param2=value2&param3=value3"
            },
          }
      },
      {
          "id": "2",
          "type": "connectors",
          "attributes": {
              "name": "Redshift",
              "connector-type": "source",
              "workspace-id": 8,
              "created-at": "2024-01-18T12:02:03.864Z",
              "updated-at": "2024-01-18T12:02:03.864Z",
              "configuration": {
                  "host": "default-workgroup.253707965345.us-east-1.redshift-serverless.amazonaws.com",
                  "port": "5439",
                  "schema": "public",
                  "database": "dev",
                  "credentials": {
                      "password": "Multiwoven2023",
                      "username": "reverse_etl",
                      "auth_type": "username/password"
                  }
              },
              "connector-name": "Redshift",
              "icon": "redshift.svg"
          }
      }
  ]

interface Payload {
	id: string;
  type:string;
	attributes: {
    name:string;
		connector_type: string;
		workspace_id: number;
		created_at: string;
		updated_at: string;
		configuration: {
			host: string;
			role: string;
			schema: string;
			database: string;
			warehouse: string;
			credentials: {
				password: string;
				username: string;
				auth_type: string;
			};
			jdbc_url_params: string;
		};
	};
  connector_name: string;
	icon: string;
	status?: string;
}

const ConnectorTable = ({ payload }: { payload: Payload[] }) => {
	const navigate = useNavigate();
	console.log("Payload:", payload);

	return (
		<TableContainer>
			<Table variant='simple'>
				<Thead>
					<Tr>
						<Th>Name</Th>
						<Th>Type</Th>
						<Th>Last Updated</Th>
						<Th>Status</Th>
					</Tr>
				</Thead>
				<Tbody>
					{samplePayload.map((item) => (
						<Tr
							onClick={() =>
								navigate(
									"/" +
										item.attributes.connector_type +
										"s/" +
										item.id +
										"?type=" +
										item.attributes.connector_type +
										"&name=" +
										item.connector_name.toLowerCase()
								)
							}
							key={item.id}
							_hover={{ backgroundColor: "gray.100" }}
						>
							<Td>
								<Text as='b'>{item.attributes.name}</Text>
							</Td>
							<Td>
								<Flex>
									<Image
										src={"/icons/" + item.icon}
										alt={`${item.connector_name} Icon`}
										boxSize='20px'
										mr={2}
									/>
									<Text fontSize='sm'>{item.connector_name}</Text>
								</Flex>
							</Td>
							<Td>{item.attributes.updated_at}</Td>
							<Td>
								<Badge colorScheme='blue' p={2} rounded='lg'>
									{item.status}
								</Badge>
							</Td>
						</Tr>
					))}
				</Tbody>
			</Table>
		</TableContainer>
	);
};

export default ConnectorTable;
