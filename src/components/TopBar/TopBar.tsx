import { Button, Flex, HStack, Heading } from "@chakra-ui/react";

type TopBarType = {
	name: string;
	ctaName?: string;
	ctaIcon?: JSX.Element;
	ctaColor?: string;
	ctaBgColor?: string;
	ctaHoverBgColor?: string;
	onCtaClicked?: () => void;
	isCtaVisible?: boolean;
	extra?: JSX.Element;
	ctaButtonVariant?: string;
};

const TopBar = ({
	name,
	ctaName = "",
	ctaIcon,
	onCtaClicked = () => {},
	isCtaVisible,
	extra,
	ctaButtonVariant = "solid",
}: TopBarType): JSX.Element => (
	<Flex
		justifyContent='space-between'
		borderColor='gray.400'
		marginBottom='30px'
	>
		<Heading fontWeight='700' size='md'>
			{name}
		</Heading>
		<HStack spacing={2}>
			{extra}
			{isCtaVisible ? (
				<Button
					variant={ctaButtonVariant}
					leftIcon={ctaIcon}
					size='md'
					onClick={onCtaClicked}
				>
					{ctaName}
				</Button>
			) : (
				<></>
			)}
		</HStack>
	</Flex>
);

export default TopBar;
