import { Box, Button, Flex, HStack, Icon, Text } from "@chakra-ui/react";
import { FiBookOpen, FiHeadphones } from "react-icons/fi";
import { Link } from "react-router-dom";

type ButtonConfig = {
	name: string;
	type?: "button" | "reset" | "submit";
	onClick?: () => void;
	isDisabled?: boolean;
	isLoading?: boolean;
	color?: string;
	bgColor?: string;
	hoverColor?: string;
	hoverBgColor?: string;
};

type ModelFooterProps = {
	buttons: ButtonConfig[];
	isBackRequired?: boolean;
};

const ModelFooter = ({
	buttons,
	isBackRequired = false,
}: ModelFooterProps): JSX.Element => {
	return (
		<Box
			position='fixed'
			left='0'
			right='0'
			borderWidth='thin'
			bottom='0'
			backgroundColor='#fff'
			padding='10px'
			display='flex'
			justifyContent='center'
			minHeight='80px'
			zIndex='1'
		>
			<Box
				maxWidth='850px'
				width='100%'
				display='flex'
				justifyContent='end'
				alignItems='center'
			>
				<HStack spacing={3}>
					{buttons.map((button, index) => (
						<Button
							key={index}
							type={button.type || "button"}
							onClick={button.onClick}
							size='lg'
							isDisabled={button.isDisabled}
							isLoading={button.isLoading}
							color={button.color}
							bgColor={button.bgColor}
							_hover={{
								color: button.hoverColor,
								bgColor: button.hoverBgColor,
							}}
						>
							{button.name}
						</Button>
					))}
				</HStack>
			</Box>
		</Box>
	);
};

export default ModelFooter;
