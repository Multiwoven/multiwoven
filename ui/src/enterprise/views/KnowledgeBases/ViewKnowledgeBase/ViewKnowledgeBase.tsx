import ContentContainer from '@/components/ContentContainer';
import DataTable from '@/components/DataTable';
import TableBox from '@/components/TableBox';
import TopBar from '@/components/TopBar';
import { Box, Button, Icon, IconButton, Input, Text, useDisclosure } from '@chakra-ui/react';

import Pagination from '@/components/EnhancedPagination';
import { usePagination } from '@/hooks/usePagination';
import { ViewKBColumns } from './ViewKBColumns';
import { FiPlus, FiSettings } from 'react-icons/fi';
import { useRef, useState } from 'react';
import useKnowledgeBaseQueries from '@/enterprise/hooks/queries/useKnowledgeBaseQueries';
import { useParams } from 'react-router-dom';
import CreateAndViewKBDrawer from '../CreateAndViewKBDrawer';
import EmptyState from '@/components/EmptyState/EmptyState';
import NoFiles from '@/assets/images/NoFiles.svg';
import useKnowledgeBaseMutations from '@/enterprise/hooks/mutations/useKnowledgeBaseMutations';
import ViewKBFile from './ViewKBFile';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';
import RoleAccess from '@/enterprise/components/RoleAccess';
import { UserActions } from '@/enterprise/types';
import Loader from '@/components/Loader';
import ConfirmDeleteModal from '@/components/ConfirmDeleteModal';

const ViewKnowledgeBase = () => {
  const [file, setFile] = useState<{ fileName: string | null; file: Blob | null }>({
    fileName: null,
    file: null,
  });
  const [openPreviewModal, setOpenPreviewModal] = useState(false);
  const { currentPage, handlePageChange } = usePagination();
  const { isOpen, onOpen, onClose } = useDisclosure();
  const {
    isOpen: isDeleteFileModalOpen,
    onOpen: onDeleteFileModalOpen,
    onClose: onDeleteFileModalClose,
  } = useDisclosure();
  const [selectedFile, setSelectedFile] = useState<{ fileId: string; fileName: string } | null>(
    null,
  );

  const { id } = useParams();

  const apiErrorToast = useAPIErrorsToast();
  const showToast = useCustomToast();
  const errorToast = useErrorToast();

  const fileInputRef = useRef<HTMLInputElement>(null);

  const { useGetAllKnowledgeBaseFiles, useGetKnowledgeBase } = useKnowledgeBaseQueries();
  const {
    uploadKnowledgeBaseFileMutation,
    getKnowledgeBaseFileMutation,
    deleteKnowledgeBaseFileMutation,
  } = useKnowledgeBaseMutations();

  const { data: knowledgeBaseFiles, isLoading: isLoadingKnowledgeBaseFiles } =
    useGetAllKnowledgeBaseFiles(id as string);
  const { data: currentKnowledgeBase, isLoading: isLoadingCurrentKnowledgeBase } =
    useGetKnowledgeBase(id as string);

  const handleAddFile = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    if (!selectedFile) return;

    uploadKnowledgeBaseFileMutation.mutate(
      {
        knowledgeBaseId: id as string,
        file: selectedFile,
      },
      {
        onSuccess: (data) => {
          if (data.errors) {
            apiErrorToast(data.errors);
          }
        },
        onError: (error) => {
          errorToast('Unable to upload file: ' + error.message, true, null, true);
        },
      },
    );
  };

  const handleDownloadFile = (fileId: string, fileName: string) => {
    getKnowledgeBaseFileMutation.mutate(
      {
        knowledgeBaseId: id as string,
        fileId: fileId,
      },
      {
        onSuccess: (data) => {
          if (data) {
            const url = window.URL.createObjectURL(data);
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            a.click();
            window.URL.revokeObjectURL(url);
            showToast({
              title: 'File downloaded successfully',
              description: 'Downloaded file: ' + fileName,
              status: CustomToastStatus.Success,
              isClosable: true,
              duration: 3000,
              position: 'bottom-right',
            });
          } else {
            errorToast('Unable to download file', true, null, true);
          }
        },
      },
    );
  };

  const handlePreviewFile = (fileId: string, fileName: string) => {
    getKnowledgeBaseFileMutation.mutate(
      {
        knowledgeBaseId: id as string,
        fileId: fileId,
      },
      {
        onSuccess: (data) => {
          setFile({ fileName: fileName, file: data });
          setOpenPreviewModal(true);
        },
      },
    );
  };

  if (isLoadingKnowledgeBaseFiles || isLoadingCurrentKnowledgeBase) {
    return <Loader />;
  }

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name={currentKnowledgeBase?.data?.attributes.name ?? ''}
          breadcrumbSteps={[
            { name: 'Knowledge Bases', url: '/knowledge-bases' },
            { name: currentKnowledgeBase?.data?.attributes.name ?? '', url: '' },
          ]}
          extra={
            <Box display='flex' gap='12px'>
              <RoleAccess location='knowledge_base' type='item' action={UserActions.Create}>
                <>
                  <Button
                    leftIcon={<FiPlus />}
                    aria-label='Add File'
                    variant='shell'
                    w='fit-content'
                    onClick={handleAddFile}
                    isLoading={uploadKnowledgeBaseFileMutation.isPending}
                    loadingText='Uploading...'
                    isDisabled={uploadKnowledgeBaseFileMutation.isPending}
                  >
                    Add Files
                  </Button>
                  <Input
                    ref={fileInputRef}
                    type='file'
                    onChange={handleFileChange}
                    data-testid='custom-visual-file-input'
                    size='md'
                    display='none'
                    placeholder='Select a file'
                    fontSize='sm'
                    fontWeight='medium'
                    color='black.100'
                    accept='.pdf,.docx'
                    p={1}
                  />
                </>
              </RoleAccess>
              <RoleAccess location='knowledge_base' type='item' action={UserActions.Read}>
                <RoleAccess location='connector' type='item' action={UserActions.Read}>
                  <IconButton
                    aria-label='Edit Knowledge Base'
                    data-testid='settings-button'
                    icon={<FiSettings />}
                    variant='shell'
                    w='fit-content'
                    onClick={() => {
                      onOpen();
                    }}
                    isDisabled={!currentKnowledgeBase?.data?.attributes}
                  />
                </RoleAccess>
              </RoleAccess>
            </Box>
          }
        />
        <TableBox
          pagination={
            knowledgeBaseFiles?.links && (
              <Pagination
                links={knowledgeBaseFiles.links}
                currentPage={currentPage}
                handlePageChange={handlePageChange}
              />
            )
          }
        >
          {knowledgeBaseFiles?.data && knowledgeBaseFiles?.data?.length > 0 ? (
            <DataTable
              columns={ViewKBColumns({
                handleDownload: handleDownloadFile,
                handlePreview: handlePreviewFile,
                handleDelete: (fileId, fileName) => {
                  setSelectedFile({ fileId, fileName });
                  onDeleteFileModalOpen();
                },
              })}
              data={knowledgeBaseFiles?.data ?? []}
              tbodyTestId='kb-file-table-tbody'
            />
          ) : (
            <Box width='100%' height='100%' pt='24px' pb='48px'>
              <EmptyState
                description="This vector store is empty. You haven't added any files yet."
                image={NoFiles}
                height='fit-content'
                width='100%'
                buttonProps={{
                  variant: 'outline',
                  size: 'sm',
                  onClick: handleAddFile,
                  paddingX: '12px',
                  isLoading: uploadKnowledgeBaseFileMutation.isPending,
                  loadingText: 'Uploading...',
                  isDisabled: uploadKnowledgeBaseFileMutation.isPending,
                  'data-testid': 'kb-empty-add-files-button',
                }}
                buttonChildren={
                  !uploadKnowledgeBaseFileMutation.isPending ? (
                    <Box display='flex' gap='8px' alignItems='center'>
                      <Icon as={FiPlus} size='12px' />
                      <Text size='sm'>Add Files</Text>
                    </Box>
                  ) : undefined
                }
                buttonRbac={{
                  location: 'knowledge_base',
                  action: UserActions.Create,
                }}
              />
            </Box>
          )}
        </TableBox>
      </ContentContainer>
      {currentKnowledgeBase?.data?.attributes && (
        <CreateAndViewKBDrawer
          isOpen={isOpen}
          onClose={onClose}
          viewOnly={true}
          defaultPayload={currentKnowledgeBase?.data?.attributes}
        />
      )}
      <ViewKBFile
        file={file.file as Blob}
        fileName={file.fileName as string}
        open={openPreviewModal}
        onClose={() => setOpenPreviewModal(false)}
      />
      <ConfirmDeleteModal
        open={isDeleteFileModalOpen}
        title='Are you sure you want to delete this file?'
        description={`This action will permanently delete ${selectedFile?.fileName} from the knowledge base. This cannot be undone.`}
        onDelete={() => {
          if (selectedFile) {
            deleteKnowledgeBaseFileMutation.mutate(
              {
                knowledgeBaseId: id as string,
                fileId: selectedFile.fileId,
              },
              {
                onSuccess: () => {
                  setSelectedFile(null);
                  onDeleteFileModalClose();
                },
              },
            );
          }
        }}
        onClose={() => {
          setSelectedFile(null);
          onDeleteFileModalClose();
        }}
        isDeleting={deleteKnowledgeBaseFileMutation.isPending}
      />
    </Box>
  );
};

export default ViewKnowledgeBase;
