import {
	Box,
	Card,
	CardBody,
	Heading,
	Image,
	SimpleGrid,
	Stack,
	Text,
} from "@chakra-ui/react";
import { modelMethods } from "./methods";
import { useContext } from "react";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { ModelMethodType } from "./types";

const ModelMethod = () => {
	const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);

	const handleOnClick = (method:ModelMethodType) => {
		if (stepInfo?.formKey) {
			console.log(stepInfo?.formKey);
			
			handleMoveForward(stepInfo.formKey, method.name);
		}
	};
	return (
		<>
			<Box mx='auto' w='6xl'>
				<SimpleGrid columns={3} spacing={8}>
					{modelMethods.map((method, index) => (
						<Card
							maxW='sm'
							key={index}
							_hover={method.enabled ? { bgColor: "gray.50" } : {}}
							variant={!method.enabled ? "filled" : "elevated"}
							onClick={() => handleOnClick(method)}
						>
							<CardBody>
								<Image
									src={method.image}
									alt={method.type}
									borderRadius='lg'
									w='full'
								/>
								<Stack mt='6' spacing='3'>
									<Heading size='md'>{method.name}</Heading>
									<Text>{method.description}</Text>
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
