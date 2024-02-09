import {
	Button,
	Center,
	Flex,
	Heading,
	Image,
	Text,
	VStack,
} from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import NoModelsImage from "@/assets/images/NoModels.png";
import { useNavigate } from "react-router-dom";

const NoModels = (): JSX.Element => {
	const navigate = useNavigate();
	return (
		<Flex
			width='100%'
			height='100%'
			alignContent='center'
			justifyContent='center'
		>
			<Center>
				<VStack spacing={8}>
					<VStack>
						<Image src={NoModelsImage} />
						<Heading size='xs'>No models added</Heading>
						<Text size='sm'>
							Add a model to describe how your data source will be queried{" "}
						</Text>
					</VStack>
					<Button onClick={() => navigate("new")} leftIcon={<FiPlus />}>
						Add Model
					</Button>
				</VStack>
			</Center>
		</Flex>
	);
};

export default NoModels;
