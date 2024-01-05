import {
    Table,
    Thead,
    Tbody,
    Tfoot,
    Tr,
    Th,
    Td,
    TableCaption,
    TableContainer,
  } from '@chakra-ui/react'

const ConnectorTable = ( payload:any ) => {
    console.log(payload);
    
    return (
    <TableContainer>
    <Table variant='simple'>
        {/* <TableCaption>Imperial to metric conversion factors</TableCaption> */}
        <Thead>
            <Tr>
                <Th>To convert</Th>
                <Th>into</Th>
                <Th isNumeric>multiply by</Th>
            </Tr>
        </Thead>
        <Tbody>
            {/* {payload.payload.map((item:any) => {
            <Tr>
                <Td>{item.id}</Td>
                <Td>
                    millimetres (mm)
                </Td>
                <Td isNumeric>25.4</Td>
            </Tr>
            })}; */}
        </Tbody>    
    </Table>
    </TableContainer>
    )
}

export default ConnectorTable;