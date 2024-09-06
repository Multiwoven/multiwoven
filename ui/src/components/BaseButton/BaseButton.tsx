import { Button } from '@chakra-ui/react';

type BaseButtonProps = {
  variant: string;
  onClick: () => void;
  text: string;
  color: string;
  leftIcon?: React.ReactElement;
  isDisabled?: boolean;
  isLoading?: boolean;
};

const BaseButton = ({
  variant,
  onClick,
  text,
  color,
  leftIcon,
  isDisabled = false,
  isLoading = false,
}: BaseButtonProps) => (
  <Button
    variant={variant}
    borderRadius='6px'
    minWidth={0}
    width='auto'
    onClick={onClick}
    color={color}
    leftIcon={leftIcon}
    isDisabled={isDisabled}
    isLoading={isLoading}
  >
    {text}
  </Button>
);

export default BaseButton;
