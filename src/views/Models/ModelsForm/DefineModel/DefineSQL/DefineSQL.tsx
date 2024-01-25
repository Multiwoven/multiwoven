import { Box, VStack } from "@chakra-ui/react";

const DefineSQL = (): JSX.Element => {
	console.log('sql');
	
	return (
		<Box w='6xl' mx='auto'>
			<VStack>
				<Box border='1px' w='4xl' h="100">Query and Monaco Editor</Box>
				<Box border='1px' w='4xl' >Query Output</Box>
			</VStack>
		</Box>
	);
};

export default DefineSQL;
