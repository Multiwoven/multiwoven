import { Box, HStack, Text } from "@chakra-ui/layout";

const AuthFooter = (): JSX.Element => {
	return (
		<Box
			position='fixed'
			right='0'
			// borderWidth='thin'
			bottom='0'
			backgroundColor='#fff'
			display='flex'
			justifyContent='center'
			minHeight='80px'
			zIndex='1'
			width='full'
			alignItems='center'
		>
			<HStack>
				<Text>© Multiwoven Inc. All rights reserved.</Text>{" "}
				<Text fontWeight='bold'>Terms of use</Text> <Text>•</Text> <Text fontWeight='bold'>Privacy Policy</Text>
			</HStack>
		</Box>
	);
};

export default AuthFooter;