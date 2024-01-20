import {
	Avatar,
	HStack,
	Table,
	Tbody,
	Td,
	Th,
	Thead,
	Tr,
	Text,
} from "@chakra-ui/react";

import Klaviyo from '../../assets/icons/klaviyo.svg'

type Models = {
	data: {
		id: string;
		type: string;
		attributes: {
			name: string;
			description: string;
			query: string;
			query_type: string;
			created_at: string;
			updated_at: string;
		};
	}[];
	links: {
		self: string;
		first: string;
		prev: string;
		next: string;
		last: string;
	};
};

const ModelTable = ({ models }: { models: Models }): JSX.Element => {
	console.log(models);

	return (
		<Table size='sm' variant='simple' border='1'>
			<Thead>
				<Tr>
					<Th fontSize={12}>NAME</Th>
					<Th fontSize={12}>METHOD</Th>
					<Th fontSize={12}>LAST UPDATED</Th>
				</Tr>
			</Thead>
			<Tbody>
				{models.data.map((model) => (
					<Tr key={model.id}>
						<Td>
							<HStack spacing='4'>
								<Avatar
									name={model.attributes.name}
									src={'../../assets/icons/' + model.attributes.name + '.svg'}
									boxSize='8'
								/>
								<Text fontWeight='medium'>{model.attributes.name}</Text>
							</HStack>
						</Td>
						<Td>
							<Text>{model.attributes.query_type}</Text>
						</Td>
						<Td>
							<Text>{model.attributes.updated_at}</Text>
						</Td>
					</Tr>
				))}
			</Tbody>
		</Table>
	);
};
export default ModelTable;
