import { Box, Table, Tbody, Td, Th, Thead, Tr } from "@chakra-ui/react";
import { TableType } from "./types";

const GenerateTable = ({ title, data }: TableType): JSX.Element => {
	return (
		<Box mt={8} border="1 | JSX.Elementpx"  borderColor="gray.100" borderRadius="lg">
			{title ? title : <></>}
			<Table>
				<Thead bgColor={'gray.200'}>
					<Tr>
						{data.columns.map((column, index) => (
							<Th key={index}>{column}</Th>
						))}
					</Tr>
				</Thead>
				<Tbody>
					{data.data.map((row, rowIndex) => (
						<Tr key={rowIndex} _hover={{backgroundColor: 'gray.100'}}>
							{Object.values(row).map((value, valueIndex) => (
								<Td key={valueIndex}>{value}</Td>
							))}
						</Tr>
					))}
				</Tbody>
			</Table>
		</Box>
	);
};

export default GenerateTable;
