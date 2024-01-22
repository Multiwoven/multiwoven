import {
	Box,
	Button,
	ButtonGroup,
	Card,
	CardBody,
	CardFooter,
	Divider,
	Flex,
	Heading,
	Image,
	SimpleGrid,
	Stack,
	Text,
} from "@chakra-ui/react";
import { modelMethods } from "./methods";

const ModelMethod = () => {
	return (
		<>
			<Box mx='auto' w='6xl'>
				<SimpleGrid columns={3} spacing={8}>
					{modelMethods.map((method, index) => (
						<Card maxW='sm' key={index}  _hover={method.enabled ? {bgColor:"gray.50"} : {}} variant={!method.enabled ? 'filled' : 'elevated' }>
							<CardBody>
								<Image
									src={method.image}
									alt={method.type}
									borderRadius='lg'
								/>
								<Stack mt='6' spacing='3'>
									<Heading size='md'>{method.name}</Heading>
									<Text>
                                        {method.description}
									</Text>
								</Stack>
							</CardBody>
						</Card>
					))}
				</SimpleGrid>
			</Box>
		</>
	);
};

export default ModelMethod;
