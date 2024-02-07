import { Box, HStack, Text } from "@chakra-ui/layout";
import { Link } from "react-router-dom";

const AuthFooter = (): JSX.Element => {
	return (
		<Box
			position='fixed'
			right='0'
			bottom='0'
			backgroundColor='gray.100'
			display='flex'
			justifyContent='center'
			minHeight='80px'
			zIndex='1'
			width='full'
			alignItems='center'
		>
			<HStack>
				<Text color='black.100' size='md'>© Multiwoven Inc. All rights reserved.</Text>{" "}
				<Link to='https://multiwoven.com/terms'>
					<Text color='brand.500' size='md'>Terms of use</Text>
				</Link>
				<Text size='md'>•</Text>{" "}
				<Link to='https://multiwoven.com/privacy'>
					<Text color='brand.500' size='md'>Privacy Policy</Text>
				</Link>
			</HStack>
		</Box>
	);
};

export default AuthFooter;
