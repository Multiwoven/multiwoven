import { Box, Flex, Image, Table, Tbody, Td, Text, Th, Thead, Tr } from "@chakra-ui/react";
import { TableType } from "./types";

const GenerateTable = ({
	title,
	data,
	size,
	headerColor,
	headerColorVisible,
	borderRadius,
	maxHeight,
	onRowClick,
}: TableType): JSX.Element => {
	const theadProps = headerColorVisible
		? { bgColor: headerColor || "gray.200" }
		: {};
	return (
		<Box
			border='1px'
			borderColor='gray.400'
			borderRadius={borderRadius || "lg"}
			maxHeight={maxHeight}
			overflowX='scroll'
		>
			{title ? title : <></>}
			<Table size={size} maxHeight={maxHeight}>
				<Thead {...theadProps} bgColor='gray.300'>
					<Tr>
						{data.columns.map((column, index) => (
							<Th key={index}>{column.name}</Th>
						))}
					</Tr>
				</Thead>
				<Tbody>
					{data.data.map((row, rowIndex) => (
						<Tr
							key={rowIndex}
							_hover={{ backgroundColor: "gray.100", cursor: "pointer" }}
							onClick={() => onRowClick?.(row)}
						>
							{data.columns.map((column, columnIndex) => (
								<Td key={columnIndex}>
                {column.showIcon ? (
                  <Flex flexDir='row' alignItems='center' alignContent='center'>
                    <Image src={'/src/assets/icons/' + row.icon} h={10} p={1} border='1px' borderRadius='lg' borderColor='gray.400' />
                    <Text fontSize='md' mx={2}>
                      {row[column.key as keyof typeof row]}
                    </Text>
                  </Flex>
                ) : (
                  row[column.key as keyof typeof row]
                )}
              </Td>
              
							))}
						</Tr>
					))}
				</Tbody>
			</Table>
		</Box>
	);
};

export default GenerateTable;
