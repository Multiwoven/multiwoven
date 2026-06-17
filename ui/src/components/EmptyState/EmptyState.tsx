import RoleAccess from '@/enterprise/components/RoleAccess';
import { RoleItem } from '@/enterprise/services/types';
import { UserActions } from '@/enterprise/types';
import { Center, Flex, VStack, Image, Text, Button, ButtonProps } from '@chakra-ui/react';

export type EmptyStateButtonProps = ButtonProps & {
  [Key in `data-${string}`]?: string | undefined;
};

type EmptyStateProps = {
  title?: string;
  description?: string;
  height?: string;
  width?: string;
  image?: string;
  buttonText?: string;
  buttonChildren?: React.ReactNode;
  buttonProps?: EmptyStateButtonProps;
  showButton?: boolean;
  buttonRbac?: {
    location: keyof RoleItem['attributes']['policies']['permissions'];
    action: UserActions;
    orAction?: UserActions;
  };
};

const EmptyState = ({
  height = '70vh',
  width = '100%',
  title,
  description,
  image,
  buttonText,
  buttonChildren,
  buttonProps,
  showButton = true,
  buttonRbac,
}: EmptyStateProps) => {
  const BaseButton = () => {
    return (
      <Button
        variant={buttonProps?.variant || 'solid'}
        leftIcon={buttonProps?.leftIcon}
        onClick={buttonProps?.onClick || (() => {})}
        paddingX='16px'
        width={'fit-content'}
        data-testid='empty-state-button'
        {...buttonProps}
      >
        {buttonChildren}
        {buttonText}
      </Button>
    );
  };
  return (
    <Flex width={width} height={height} alignContent='center' justifyContent='center'>
      <Center>
        <VStack spacing={8}>
          <VStack>
            <Image src={image} alt='empty state image' data-testid='empty-state-image' />
            {title && (
              <Text size='xl' fontWeight='semibold'>
                {title}
              </Text>
            )}
            {description && (
              <Text size='sm' color='black.100'>
                {description}
              </Text>
            )}
          </VStack>
          {showButton &&
            (buttonRbac ? (
              <RoleAccess
                location={buttonRbac.location}
                type='item'
                action={buttonRbac.action}
                orAction={buttonRbac.orAction}
              >
                <BaseButton />
              </RoleAccess>
            ) : (
              <BaseButton />
            ))}
        </VStack>
      </Center>
    </Flex>
  );
};

export default EmptyState;
