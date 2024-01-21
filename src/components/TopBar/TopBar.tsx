import { Button, Flex, Heading } from "@chakra-ui/react";

type TopBarType = {
	name: string;
	ctaName: string;
	ctaIcon: JSX.Element;
	ctaColor: string;
	ctaBgColor: string;
  ctaHoverBgColor: string;
	onCtaClicked: () => void;
	isCtaVisible?: boolean;
};

const TopBar = ({
	name,
	ctaName = "",
	ctaIcon,
	onCtaClicked = () => {},
	isCtaVisible,
  ctaBgColor,
  ctaHoverBgColor,
  ctaColor
}: TopBarType): JSX.Element => (
	<Flex justifyContent='space-between' borderColor='gray.300'>
		<Heading size='xl' _dark={{ color: "white" }}>
			{name}
		</Heading>
		{isCtaVisible ? (
			<Button
				leftIcon={ctaIcon}
				backgroundColor={ctaBgColor}
				_hover={{ bgColor: ctaHoverBgColor }}
				color={ctaColor}
				p={4}
				fontSize={16}
				size='sm'
				onClick={onCtaClicked}
			>
				{ctaName}
			</Button>
		) : (
			<></>
		)}
	</Flex>
);

export default TopBar;
