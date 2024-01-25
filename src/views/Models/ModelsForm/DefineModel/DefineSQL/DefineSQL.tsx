import {
	AbsoluteCenter,
	Box,
	Button,
	Center,
	Flex,
	HStack,
	Image,
	Spacer,
	Text,
	VStack,
} from "@chakra-ui/react";

import StarsImage from "@/assets/images/stars.svg";
import EmptyQueryPreviewImage from "@/assets/images/EmptyQueryPreview.png";

import Editor from "@monaco-editor/react";
import { useContext, useState } from "react";
import { getModelPreview } from "@/services/models";
import { ConvertModelPreviewToTableData } from "@/utils/ConvertToTableData";
import GenerateTable from "@/components/Table/Table";
import { TableDataType } from "@/components/Table/types";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";

const DefineSQL = (): JSX.Element => {
	const [query, setQuery] = useState("");
	const [tableData, setTableData] = useState<null | TableDataType>();

	const { handleMoveForward } = useContext(SteppedFormContext);

	function handleEditorChange(value: string | undefined) {
		if (value) setQuery(value);
	}

	async function getPreview() {
		console.log(query);
		let data = await getModelPreview();
		if (data) {
			const columns = Object.keys(data.data[0]);
			setTableData(ConvertModelPreviewToTableData(data.data, columns));
		}
	}

	return (
		<Box w='6xl' mx='auto'>
			<VStack>
				<Box
					border='1px'
					borderColor='gray.300'
					w='4xl'
					minH='100%'
					h='xs'
					rounded='xl'
				>
					<Flex bgColor='gray.200' p={2} roundedTop='xl'>
						<Flex>
							<Image src='@/assets/icons/redshift.svg' />
							<Text>difi</Text>
						</Flex>
						<Spacer />
						<HStack spacing={3}>
							<Button
								bgColor='white'
								_hover={{ bgColor: "gray.100" }}
								variant='outline'
								borderColor={"gray.500"}
								onClick={getPreview}
							>
								{" "}
								Run Query{" "}
							</Button>
							<Button
								bgColor='white'
								_hover={{ bgColor: "gray.100" }}
								variant='outline'
								borderColor={"gray.500"}
							>
								<Image src={StarsImage} w={6} mr={2} /> Beautify
							</Button>
						</HStack>
					</Flex>
					<Box p={3} w='100%'>
						<Editor
							width='100%'
							height='250px'
							language='mysql'
							defaultLanguage='mysql'
							defaultValue='Enter your query...'
							onChange={handleEditorChange}
							theme='light'
						/>
					</Box>
				</Box>

				{tableData ? (
					<Box w='4xl' h='fit'>
						<GenerateTable data={tableData} size='sm' borderRadius='xl' />
					</Box>
				) : (
					<Box
						border='1px'
						borderColor='gray.300'
						w='4xl'
						minH='100%'
						h='2xs'
						rounded='xl'
						p={1}
						alignItems='center'
						justifyContent='center'
					>
						<VStack mx='auto' mt={12}>
							<Image src={EmptyQueryPreviewImage} h='20' />
							<Text fontSize='md' fontWeight='bold'>
								Ready to test your query?
							</Text>
							<Text fontSize='sm'>Run your query to preview the rows</Text>
						</VStack>
					</Box>
				)}
			</VStack>
		</Box>
	);
};

export default DefineSQL;
