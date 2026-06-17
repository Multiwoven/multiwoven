import ContentContainer from '@/components/ContentContainer';
import DataTable from '@/components/DataTable';
import TableBox from '@/components/TableBox';
import TopBar from '@/components/TopBar';
import { Box, Button, Icon, useDisclosure } from '@chakra-ui/react';
import { ListKBColumns } from './ListKBColumns';

import Pagination from '@/components/EnhancedPagination';
import { usePagination } from '@/hooks/usePagination';

import { useNavigate } from 'react-router-dom';
import useKnowledgeBaseQueries from '@/enterprise/hooks/queries/useKnowledgeBaseQueries';
import { FiPlus } from 'react-icons/fi';
import CreateAndViewKBDrawer from '../CreateAndViewKBDrawer';
import EmptyState from '@/components/EmptyState/EmptyState';
import NoKnowledgeBases from '@/assets/images/NoKnowledgeBases.svg';
import RoleAccess from '@/enterprise/components/RoleAccess';
import { UserActions } from '@/enterprise/types';
import Loader from '@/components/Loader';
import useKnowledgeBaseMutations from '@/enterprise/hooks/mutations/useKnowledgeBaseMutations';
import ConfirmDeleteModal from '@/components/ConfirmDeleteModal';
import { useState } from 'react';
import { KnowledgeBase } from '@/enterprise/services/knowledge-base';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import NoAccess from '../../NoAccess';

const ListKnowledgeBases = () => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const {
    isOpen: isDeleteModalOpen,
    onOpen: onDeleteModalOpen,
    onClose: onDeleteModalClose,
  } = useDisclosure();
  const { currentPage, handlePageChange } = usePagination();
  const navigate = useNavigate();

  const { useGetKnowledgeBases } = useKnowledgeBaseQueries();
  const { deleteKnowledgeBaseMutation } = useKnowledgeBaseMutations();
  const { data, refetch, isLoading } = useGetKnowledgeBases();
  const [selectedKnowledgeBase, setSelectedKnowledgeBase] = useState<KnowledgeBase | null>(null);

  const role = useRoleDataStore((state) => state.activeRole);

  if (isLoading) {
    return <Loader />;
  }

  if (role === null) {
    return <Loader />;
  }

  const hasKnowledgeBaseReadPermission = hasActionPermission(
    role,
    'knowledge_base',
    UserActions.Read,
  );

  if (!hasKnowledgeBaseReadPermission) {
    return <NoAccess />;
  }

  const hasKnowledgeBaseCreationPermission = hasActionPermission(
    role,
    'knowledge_base',
    UserActions.Create,
  );

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name='Knowledge Bases'
          description='Create and manage knowledge sources and document collections for your AI workflows.'
          extra={
            <RoleAccess location='knowledge_base' type='item' action={UserActions.Create}>
              <Button
                data-testid='kb-create-button'
                leftIcon={<FiPlus />}
                width='fit-content'
                onClick={() => {
                  onOpen();
                }}
              >
                New Knowledge Base
              </Button>
            </RoleAccess>
          }
        />
        {data?.data && data.data.length > 0 ? (
          <TableBox
            pagination={
              data?.links && (
                <Pagination
                  links={data?.links}
                  currentPage={currentPage}
                  handlePageChange={handlePageChange}
                />
              )
            }
          >
            <DataTable
              columns={ListKBColumns((id) => {
                const kb = data?.data?.find((kb) => kb.id === id);
                if (kb) {
                  setSelectedKnowledgeBase(kb);
                  onDeleteModalOpen();
                }
              })}
              data={data?.data ?? []}
              tbodyTestId='knowledge-bases-list-table-tbody'
              getRowProps={(row) => ({
                'data-testid': `kb-list-table-row-${row.original.id}`,
              })}
              onRowClick={(row) => {
                navigate(`/knowledge-bases/${row.original.id}`);
              }}
              noRowsComponent={<>No Knowledge Bases</>}
            />
          </TableBox>
        ) : (
          <EmptyState
            title='No Knowledge Bases created'
            description={
              hasKnowledgeBaseCreationPermission
                ? 'Create and manage knowledge sources and document collections for your AI workflows.'
                : 'You will be able to view the data on this page once the admin configures it'
            }
            showButton={hasKnowledgeBaseCreationPermission}
            buttonText='Create Knowledge Base'
            image={NoKnowledgeBases}
            buttonProps={{
              onClick: onOpen,
              gap: '8px',
              'data-testid': 'kb-empty-create-button',
            }}
            buttonChildren={<Icon as={FiPlus} size='16px' />}
          />
        )}
      </ContentContainer>
      <CreateAndViewKBDrawer
        isOpen={isOpen}
        onClose={onClose}
        viewOnly={false}
        refetchKnowledgeBases={refetch}
      />
      <ConfirmDeleteModal
        open={isDeleteModalOpen}
        title='Are you sure you want to delete this Knowledge Base?'
        description={`This action will permanently delete ${selectedKnowledgeBase?.attributes.name} and all associated files. This cannot be undone.`}
        onDelete={() => {
          if (selectedKnowledgeBase) {
            deleteKnowledgeBaseMutation.mutate(
              {
                knowledgeBaseId: selectedKnowledgeBase.id,
              },
              {
                onSuccess: () => {
                  setSelectedKnowledgeBase(null);
                  onDeleteModalClose();
                },
              },
            );
          }
        }}
        onClose={() => {
          setSelectedKnowledgeBase(null);
          onDeleteModalClose();
        }}
        isDeleting={deleteKnowledgeBaseMutation.isPending}
      />
    </Box>
  );
};

export default ListKnowledgeBases;
