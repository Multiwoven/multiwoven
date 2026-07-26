import { ColumnDef } from '@tanstack/react-table';
import { Text } from '@chakra-ui/react';

import { formatTimestamp } from '@/utils/formatTimestamp';
import StatusTag from '@/components/StatusTag';
import { StatusTagText, StatusTagVariants } from '@/components/StatusTag/StatusTag';
import { formatFileSize } from '@/enterprise/views/Settings/EulaSetup/DocumentActions';
import { KnowledgeBaseFile } from '@/enterprise/services/knowledge-base';

import IconEntity from '@/components/IconEntity';
import { FiDownload, FiEye, FiFileText, FiTrash2 } from 'react-icons/fi';
import HorizontalMenuActions from '@/components/HorizontalMenuActions';
import MenuAction from '@/enterprise/components/MenuAction';
import RoleAccess from '@/enterprise/components/RoleAccess';
import { UserActions } from '@/enterprise/types';

type ViewKBColumnsProps = {
  handleDownload: (fileId: string, fileName: string) => void;
  handlePreview: (fileId: string, fileName: string) => void;
  handleDelete: (fileId: string, fileName: string) => void;
};

export const ViewKBColumns = ({
  handleDownload,
  handlePreview,
  handleDelete,
}: ViewKBColumnsProps) => {
  const columns: ColumnDef<KnowledgeBaseFile>[] = [
    {
      accessorKey: 'attributes.name',
      header: () => <span>Name</span>,
      cell: (info) => <IconEntity icon={FiFileText} description={info.getValue() as string} />,
    },
    {
      accessorKey: 'attributes.size',
      header: () => <span>Size</span>,
      cell: (info) => (
        <Text fontSize='14px' fontWeight={600}>
          {formatFileSize(info.getValue() as number)}
        </Text>
      ),
    },
    {
      accessorKey: 'attributes.updated_at',
      header: () => <span>Last Updated</span>,
      cell: (info) => (
        <Text fontSize='14px' fontWeight={500}>
          {formatTimestamp(info.getValue() as string)}
        </Text>
      ),
    },
    {
      accessorKey: 'attributes.upload_status',
      header: () => <span>Status</span>,
      cell: (info) => {
        const uploadStatus = info.getValue() as KnowledgeBaseFile['attributes']['upload_status'];
        let status = {
          variant: StatusTagVariants.draft,
          text: StatusTagText.processing,
        };
        let statusTestSlug = 'processing';

        switch (uploadStatus) {
          case 'processing':
            statusTestSlug = 'processing';
            status = {
              variant: StatusTagVariants.draft,
              text: StatusTagText.processing,
            };
            break;

          case 'processed':
            statusTestSlug = 'processed';
            status = {
              variant: StatusTagVariants.success,
              text: StatusTagText.processed,
            };
            break;

          case 'failed':
            statusTestSlug = 'failed';
            status = {
              variant: StatusTagVariants.failed,
              text: StatusTagText.failed,
            };
            break;

          case 'failed_to_delete':
            statusTestSlug = 'failed-to-delete';
            status = {
              variant: StatusTagVariants.failed,
              text: StatusTagText.failed_to_delete,
            };
            break;

          default:
            break;
        }
        const statusTestId = `kb-file-status-${statusTestSlug}`;
        return <StatusTag variant={status.variant} status={status.text} testId={statusTestId} />;
      },
    },
    {
      accessorKey: 'attributes',
      header: '',
      cell: (row) => {
        const id = row.row.original.id;
        return (
          <RoleAccess
            location='knowledge_base'
            type='item'
            action={UserActions.Read}
            orAction={UserActions.Delete}
          >
            <HorizontalMenuActions
              variant='light'
              ml={0}
              px={0}
              placement='bottom-end'
              contentWidth='160px'
            >
              <>
                <RoleAccess location='knowledge_base' type='item' action={UserActions.Read}>
                  <MenuAction
                    label='Preview'
                    variant='edit'
                    icon={FiEye}
                    onClick={() => {
                      handlePreview(id, row.row.original.attributes.name);
                    }}
                    onClose={() => {}}
                    isDisabled={false}
                    testId='preview-knowledge-base-file'
                  />
                </RoleAccess>
                <RoleAccess location='knowledge_base' type='item' action={UserActions.Read}>
                  <MenuAction
                    label='Download'
                    variant='edit'
                    icon={FiDownload}
                    onClick={() => {
                      handleDownload(id, row.row.original.attributes.name);
                    }}
                    onClose={() => {}}
                    isDisabled={false}
                    testId='download-knowledge-base-file'
                  />
                </RoleAccess>
                <RoleAccess location='knowledge_base' type='item' action={UserActions.Delete}>
                  <MenuAction
                    label='Delete'
                    variant='delete'
                    icon={FiTrash2}
                    onClick={() => {
                      handleDelete(id, row.row.original.attributes.name);
                    }}
                    onClose={() => {}}
                    testId='delete-knowledge-base-file'
                    isDisabled={false}
                  />
                </RoleAccess>
              </>
            </HorizontalMenuActions>
          </RoleAccess>
        );
      },
    },
  ];
  return columns;
};
