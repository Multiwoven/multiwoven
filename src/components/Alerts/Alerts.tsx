import { AlertData } from '../commonTypes';
import { Alert, AlertIcon, AlertDescription } from '@chakra-ui/react';

export const alertMessage: AlertData = {
  status: undefined,
  description: [''],
};

function AlertPopUp({ status, description }: AlertData) {
  return (
    <>
      {description.map((desc, index) => (
        <Alert status={status} marginBottom={5} width='fit' rounded='md' key={index}>
          <AlertIcon />
          <AlertDescription>{desc}</AlertDescription>
        </Alert>
      ))}
    </>
  );
}

export default AlertPopUp;
