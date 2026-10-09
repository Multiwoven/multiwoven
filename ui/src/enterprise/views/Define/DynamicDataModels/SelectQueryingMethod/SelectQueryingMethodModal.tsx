import BaseModal from '@/components/BaseModal';
import { Box, Text } from '@chakra-ui/react';
import { IconType } from 'react-icons/lib';
import IconEntity from '@/components/IconEntity';
import { RiBracesFill } from 'react-icons/ri';
import { BsBracesAsterisk } from 'react-icons/bs';
import DocumentationLink from '@/components/DocumentationLink';
import {
  QUERYING_METHODS,
  SelectQueryingMethodModalProps,
} from '@/enterprise/views/Define/DynamicDataModels/types.ts';

const QueryingMethod = ({
  title,
  description,
  icon,
  onClick,
}: {
  title: string;
  description: string;
  icon: IconType;
  onClick: () => void;
}) => (
  <Box
    padding='20px'
    borderWidth='1px'
    borderStyle='solid'
    borderColor='gray.400'
    borderRadius='8px'
    backgroundColor='gray.100'
    flex={1}
    cursor='pointer'
    _hover={{ borderColor: 'gray.500', backgroundColor: 'gray.200' }}
    onClick={onClick}
    data-testid={`querying-method-${title.toLowerCase().replace(/\s+/g, '-')}`}
  >
    <IconEntity icon={icon} height='40px' width='40px' />
    <Text size='lg' fontWeight={600} marginTop='12px'>
      {title}
    </Text>
    <Text size='xs' fontWeight={400} color='black.200' marginTop='4px'>
      {description}
    </Text>
  </Box>
);

const SelectQueryingMethodModal = ({
  modalOpen,
  setModalOpen,
  setQueryingMethod,
}: SelectQueryingMethodModalProps) => {
  return (
    <BaseModal
      footer={<DocumentationLink label='Read Documentation' />}
      openModal={modalOpen}
      setModalOpen={() => setModalOpen(false)}
      title='Select Querying Method'
      footerAlignment='start'
    >
      <Box display='flex' gap='20px'>
        <QueryingMethod
          title='Dynamic Querying'
          description='For queries that support dynamic values in the form of variables.'
          icon={BsBracesAsterisk}
          onClick={() => setQueryingMethod(QUERYING_METHODS.Dynamic)}
        />
        <QueryingMethod
          title='Static Querying'
          description='For queries where the query submitted to the source is fixed.'
          icon={RiBracesFill}
          onClick={() => setQueryingMethod(QUERYING_METHODS.Static)}
        />
      </Box>
    </BaseModal>
  );
};

export default SelectQueryingMethodModal;
