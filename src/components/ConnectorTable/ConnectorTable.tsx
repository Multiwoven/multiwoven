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

interface Payload {
  id: number;
  name: string;
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
  connector_definition: {
    name: string;
    icon: string;
  };
  // Add status here if it's part of your data structure
  status?: string;
}

const ConnectorTable = ({ payload }: { payload: Payload[] }) => {
  const navigate = useNavigate();  
  console.log(payload);
  

  return (
    <TableContainer>
      <Table variant="simple">
        <Thead>
          <Tr>
            <Th>Name</Th>
            <Th>Type</Th>
            <Th>Last Updated</Th>
            <Th>Status</Th>
          </Tr>
        </Thead>
        <Tbody>
          {payload.map((item) => (
            <Tr
              onClick={() => navigate("/" + item.connector_type + "s/" + item.id + "?type=" + item.connector_type + "&name=" + item.connector_definition.name.toLowerCase())}
              key={item.id}
              _hover={{ backgroundColor: "gray.100" }}
            >
              <Td>
                <Text as="b">{item.name}</Text>
              </Td>
              <Td>
                <Flex>
                  <Image
                    src={'/icons/' + item.connector_definition.icon}
                    alt={`${item.connector_definition.name} Icon`}
                    boxSize="20px"
                    mr={2}
                  />
                  <Text fontSize="sm">{item.connector_definition.name}</Text>
                </Flex>
              </Td>
              <Td>{item.updated_at}</Td>
              <Td>
                <Badge colorScheme="blue" p={2} rounded="lg">
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