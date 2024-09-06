import { AlertData } from '../commonTypes';
import { Alert, AlertIcon, AlertTitle, Box, AlertDescription } from '@chakra-ui/react';

type AlertBoxProps = {
  title: string;
  description: string;
  status: AlertData['status'];
};

const AlertBox = ({ title, description, status }: AlertBoxProps) => (
  <Alert status={status} borderRadius='8px' paddingX='16px' paddingY='12px'>
    <AlertIcon />
    <Box>
      <AlertTitle fontSize='14px' fontWeight='semibold' letterSpacing='-0.14px'>
        {title}
      </AlertTitle>
      <AlertDescription color='black.200' fontSize='12px' fontWeight={400} letterSpacing='-0.14px'>
        {description}
      </AlertDescription>
    </Box>
  </Alert>
);

export default AlertBox;
