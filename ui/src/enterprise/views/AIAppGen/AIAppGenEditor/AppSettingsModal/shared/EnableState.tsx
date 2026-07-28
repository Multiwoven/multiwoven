import { Button, Flex, Text } from '@chakra-ui/react';
import type { ReactNode } from 'react';

import { LoadingBadge } from './LoadingBadge';
import type { EnableStateCopy } from './types';

type EnableStateProps = {
  status: 'idle' | 'enabling';
  stepLabel: string;
  onEnable: () => void;
  copy: EnableStateCopy;
  visual: ReactNode;
  enableButtonTestId?: string;
};

export function EnableState({
  status,
  stepLabel,
  onEnable,
  copy,
  visual,
  enableButtonTestId,
}: EnableStateProps): JSX.Element {
  const isEnabling = status === 'enabling';

  return (
    <Flex direction='column' align='center' gap='16px' w='380px'>
      {visual}

      <Flex direction='column' gap='4px' align='center' textAlign='center'>
        <Text fontSize='md' fontWeight='semibold' color='black.500' lineHeight='24px'>
          {isEnabling ? copy.enablingTitle : copy.idleTitle}
        </Text>
        <Text fontSize='sm' color='black.100' lineHeight='20px'>
          {isEnabling ? copy.enablingDescription : copy.idleDescription}
        </Text>
      </Flex>

      {isEnabling ? (
        <LoadingBadge label={stepLabel} />
      ) : (
        <Button
          variant='outline'
          size='sm'
          w='fit-content'
          onClick={onEnable}
          data-testid={enableButtonTestId}
        >
          {copy.enableButtonLabel}
        </Button>
      )}
    </Flex>
  );
}
