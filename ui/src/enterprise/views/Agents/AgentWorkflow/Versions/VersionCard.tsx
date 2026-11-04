import SharedVersionCard, {
  VersionDisplayStatus,
} from '@/enterprise/components/Versions/VersionCard';
import VersionActionsMenu from '@/enterprise/components/Versions/VersionActionsMenu';
import { WorkflowVersionResponse } from '@/enterprise/services/types';

interface VersionCardProps {
  version: WorkflowVersionResponse;
  isCurrent: boolean;
  isLatestPublished?: boolean;
  onPreview: () => void;
  onEditDescription: () => void;
  onDelete: () => void;
}

const VersionCard = ({
  version,
  isCurrent,
  isLatestPublished = false,
  onPreview,
  onEditDescription,
  onDelete,
}: VersionCardProps) => {
  // Get the version's status from the nested workflow object
  const versionStatus = version.attributes.workflow?.attributes?.status;

  // Determine display status: Live if published, Draft if current and draft, otherwise archived
  const status: VersionDisplayStatus = isLatestPublished
    ? 'live'
    : isCurrent && versionStatus === 'draft'
      ? 'draft'
      : 'archived';

  return (
    <SharedVersionCard
      version={{
        label: `v${version.attributes.version_number}`,
        status,
        description: version.attributes.version_description || '',
        author: version.attributes.whodunnit || null,
        timestamp: version.attributes.created_at || null,
        canPreview: !isCurrent,
        canEdit: true,
        canDelete: status !== 'live' && !isCurrent,
      }}
      testId='workflow-version-item'
      versionNumber={version.attributes.version_number}
      isLatestPublished={isLatestPublished}
      previewButtonTestId='workflow-version-preview-button'
      actions={
        <VersionActionsMenu
          onEditDescription={onEditDescription}
          onDelete={onDelete}
          canDelete={status !== 'live' && !isCurrent}
          menuButtonTestId='workflow-version-menu-button'
          deleteButtonTestId='workflow-version-delete-button'
        />
      }
      onPreview={onPreview}
      onEditDescription={onEditDescription}
      onDelete={onDelete}
    />
  );
};

export default VersionCard;
