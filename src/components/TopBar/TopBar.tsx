import { Button, Flex, Heading } from "@chakra-ui/react";
import { ConnectorType } from "../commonTypes";
import titleCase from "@/utils/TitleCase";
import { FiPlus } from "react-icons/fi";

const TopBar = (props: ConnectorType) => {
	return (
		<>
			<Flex
				justifyContent='space-between'
				// alignItems='center'
				p={4}
				// borderBottom={"1px"}
				borderColor='gray.300'
				mb={4}
			>
				<Heading size='md' _dark={{color:"white"}}>{titleCase(props.connectorType)}</Heading>
				{props.buttonVisible ? (
					<Button
						leftIcon={<FiPlus color='gray.100' />}
						backgroundColor='mw_orange'
						color='gray.100'
						_hover={{ bgColor: "orange.500" }}
						fontSize={16}
						size='sm'
						onClick={props.buttonOnClick}
					>
						Add New {titleCase(props.buttonText)}
					</Button>
				) : (
					<></>
				)}
			</Flex>
		</>
	);
};

export default TopBar;
