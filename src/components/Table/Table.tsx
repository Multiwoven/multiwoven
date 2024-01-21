import {
	Avatar,
	Badge,
	Box,
	Checkbox,
	HStack,
	Icon,
	IconButton,
	Table,
	Tbody,
	Td,
	Text,
	Th,
	Thead,
	Tr,
} from "@chakra-ui/react";
import { TableDataType } from "./types";

const GenerateTable = ({ columns, data }: TableDataType): JSX.Element => {
	return (
		<>
			<Table>
				<Thead>
					<Tr>
						{columns.map((column) => (
							<Th>{column}</Th>
						))}
					</Tr>
				</Thead>
				<Tbody>
					{data.map((value) => (
						<Tr key={value}></Tr>
					))}
				</Tbody>
			</Table>
		</>
	);
};

export default GenerateTable;
