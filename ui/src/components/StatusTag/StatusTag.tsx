import { Tag, Text } from '@chakra-ui/react';

export enum StatusTagVariants {
  success = 'success',
  pending = 'pending',
  started = 'started',
  querying = 'querying',
  queued = 'queued',
  in_progress = 'in_progress',
  paused = 'paused',
  failed = 'failed',
}

type StatusTagProps = {
  variant?: StatusTagVariants;
  status: string;
};

type VariantTheme = Record<
  StatusTagVariants,
  {
    bgColor: string;
    borderColor: string;
    textColor: string;
  }
>;

const theme: VariantTheme = {
  success: {
    bgColor: 'success.100',
    borderColor: 'success.300',
    textColor: 'success.600',
  },
  failed: {
    bgColor: 'error.100',
    borderColor: 'error.300',
    textColor: 'error.600',
  },
  pending: {
    bgColor: 'warning.100',
    borderColor: 'warning.300',
    textColor: 'warning.600',
  },
  in_progress: {
    bgColor: 'warning.100',
    borderColor: 'warning.300',
    textColor: 'warning.600',
  },
  started: {
    bgColor: 'gray.100',
    borderColor: 'gray.300',
    textColor: 'gray.600',
  },
  querying: {
    bgColor: 'gray.100',
    borderColor: 'gray.300',
    textColor: 'gray.600',
  },
  queued: {
    bgColor: 'gray.100',
    borderColor: 'gray.300',
    textColor: 'gray.600',
  },
  paused: {
    bgColor: 'gray.100',
    borderColor: 'gray.300',
    textColor: 'gray.600',
  },
};

export const StatusTagText = {
  success: 'Success',
  pending: 'Pending',
  started: 'Started',
  querying: 'Querying',
  queued: 'Queued',
  in_progress: 'In Progress',
  paused: 'Paused',
  failed: 'Failed',
};

const StatusTag = ({ status, variant = StatusTagVariants.success }: StatusTagProps) => {
  return (
    <Tag
      colorScheme='teal'
      size='xs'
      bgColor={theme[variant].bgColor}
      paddingX={2}
      fontWeight={600}
      borderColor={theme[variant].borderColor}
      borderWidth='1px'
      borderStyle='solid'
      height='22px'
      borderRadius='4px'
    >
      <Text size='xs' fontWeight='semibold' color={theme[variant].textColor}>
        {status}
      </Text>
    </Tag>
  );
};

export default StatusTag;
