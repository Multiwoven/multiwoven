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
  } from '@chakra-ui/react'  
import { useNavigate } from 'react-router-dom';

const ConnectorTable = ({ payload }) => {    
    
    const navigate = useNavigate();
    
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
            {payload.map((item:any) => (
                <Tr onClick={() => navigate("/sources/" + item.id)} key={item.id} _hover={{backgroundColor:'gray.100'}}>
                    <Td>
                        <Text as="b">
                            {item.name}
                        </Text>
                    </Td>
                    <Td>
                        <Flex>
                            <Image
                            src={item.connector_definiton.icon}
                            alt={`${item.connector_definiton.name} Icon`}
                            boxSize="20px"
                            mr={2}
                            />
                            <Text fontSize="sm">{item.connector_definiton.name}</Text>
                        </Flex>
                    </Td>

                    <Td>
                        {item.updated_at}
                    </Td>

                    <Td>
                        <Badge colorScheme='green' p={2} rounded="lg">
                            {item.status}
                        </Badge>
                    </Td>
                </Tr>
            ))}
          </Tbody>    
        </Table>
      </TableContainer>
    )
  }
  
  export default ConnectorTable;
  