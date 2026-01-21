import { useState } from 'react';

import { FiTrash2, FiEdit3 } from 'react-icons/fi';
import { useNavigate, useParams } from 'react-router-dom';

import { CustomToastStatus } from '@/components/Toast';
import EditDetailsModal from '@/components/EditDetailsModal';
import MultiActionButton from '@/components/MultiActionButton/MultiActionButton';

import { deleteConnector } from '@/services/connectors';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';

import useCustomToast from '@/hooks/useCustomToast';
import HorizontalMenuActions from '@/components/HorizontalMenuActions';
import ConfirmDeleteModal from '@/components/ConfirmDeleteModal';
import { useDisclosure } from '@chakra-ui/react';

type ConnectorActionsProps = {
  connectorType: 'source' | 'destination';
  initialValues?: { name: string; description: string };
  onSave: (values: { name: string; description: string }) => void;
};

const ConnectorActions = ({ connectorType, initialValues, onSave }: ConnectorActionsProps) => {
  const [openModal, setOpenModal] = useState(false);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const showToast = useCustomToast();
  const navigate = useNavigate();
  const { connectorId } = useParams();

  const [isDeleting, setIsDeleting] = useState(false);
  const apiErrorToast = useAPIErrorsToast();

  const handleDeleteConnector = async () => {
    try {
      setIsDeleting(true);
      if (!connectorId) {
        showToast({
          status: CustomToastStatus.Error,
          title: 'Error!!',
          description: 'Connector ID not found',
        });
        return;
      }
      const response = await deleteConnector(connectorId);
      if (response?.errors) {
        apiErrorToast(response.errors);
      } else {
        showToast({
          title: 'Connector deleted successfully',
          isClosable: true,
          duration: 5000,
          status: CustomToastStatus.Success,
          position: 'bottom-right',
        });
        navigate(`/setup/${connectorType}s`);
      }
      setIsDeleting(false);
      return;
    } catch {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Error!!',
        description: 'Something went wrong while deleting the connector',
        position: 'bottom-right',
        isClosable: true,
      });
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <HorizontalMenuActions contentMargin='8px'>
      <>
        <MultiActionButton
          text='Edit Details'
          icon={FiEdit3}
          iconColor='gray.600'
          onClick={() => setOpenModal(true)}
          buttonTextColor='gray.200'
          buttonHoverColor='gray.200'
          textColor='black.500'
        />
        <MultiActionButton
          text='Delete'
          icon={FiTrash2}
          iconColor='red.600'
          onClick={onOpen}
          buttonTextColor='red.600'
          buttonHoverColor='gray.200'
          textColor='red.500'
        />
        <EditDetailsModal
          openModal={openModal}
          setModalOpen={setOpenModal}
          resourceName={connectorType === 'source' ? 'source' : 'destination'}
          onSave={(values) => {
            onSave(values);
            setOpenModal(false);
          }}
          initialValues={initialValues}
        />
        <ConfirmDeleteModal
          title={`Are you sure you want to delete this ${connectorType === 'source' ? 'source' : 'destination'}?`}
          description={`This action will delete the ${initialValues?.name} and all associated data.`}
          open={isOpen}
          onClose={onClose}
          onDelete={handleDeleteConnector}
          isDeleting={isDeleting}
        />
      </>
    </HorizontalMenuActions>
  );
};

export default ConnectorActions;
