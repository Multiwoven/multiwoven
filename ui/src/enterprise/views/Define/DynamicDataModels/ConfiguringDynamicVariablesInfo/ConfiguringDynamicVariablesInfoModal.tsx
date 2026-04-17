import BaseModal from '@/components/BaseModal';
import { Box, Text, Image, Button } from '@chakra-ui/react';
import DynamicQueryTableImage from '@/assets/images/dynamicQueryTable.svg';

const ConfiguringDynamicVariablesInfoModal = ({
  modalOpen,
  setModalOpen,
}: {
  modalOpen: boolean;
  setModalOpen: (args: boolean) => void;
}) => {
  const handleModalClose = () => setModalOpen(false);

  return (
    <BaseModal
      footer={
        <Button
          variant='solid'
          onClick={handleModalClose}
          size='md'
          w='fit-content'
          data-testid='dynamic-variables-info-understood'
        >
          Understood
        </Button>
      }
      openModal={modalOpen}
      setModalOpen={handleModalClose}
      title=''
      footerAlignment='center'
    >
      <>
        <Image src={DynamicQueryTableImage} alt='dynamic-query-table-image' />
        <Box
          display='flex'
          gap='8px'
          flexDirection='column'
          justifyContent='center'
          alignItems='center'
        >
          <Text size='xl' fontWeight={700}>
            Configuring your variables
          </Text>
          <Text size='sm' color='black.200' padding='0 48px'>
            Enter your SQL query using dynamic variables in the format{' '}
            <Text as='span' fontWeight={600}>
              :variable
            </Text>
            {".  You'll then be prompted to add sample inputs for the variable to preview the"}
            results.
          </Text>
        </Box>
      </>
    </BaseModal>
  );
};

export default ConfiguringDynamicVariablesInfoModal;
