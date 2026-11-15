// -----------------------------------------------------------------------------
// TEMPORARY announcement banner for the new Allowed Origins feature.
//
// To REMOVE this banner entirely once the announcement period is over:
//   1. Remove <EmbedOriginsAnnouncementBanner /> from MainLayout.tsx
//   2. Delete this whole folder (components/EmbedOriginsAnnouncementBanner)
//   3. Grep for "embed-origins-announcement" and remove any lingering
//      localStorage keys if you want a fresh slate (safe to leave; harmless).
//
// To DISABLE without deleting: flip ENABLED below to false.
// -----------------------------------------------------------------------------
import { Box, CloseButton, Flex, Icon, Link, Text } from '@chakra-ui/react';
import { FiInfo } from 'react-icons/fi';
import { useEffect, useState } from 'react';
import { Link as RouterLink } from 'react-router-dom';

const ENABLED = true;
const DISMISSED_KEY = 'embed-origins-announcement-dismissed';

const EmbedOriginsAnnouncementBanner = () => {
  const [visible, setVisible] = useState(false);

  // Read the dismissed flag after mount so SSR / tests don't touch storage
  // during render.
  useEffect(() => {
    if (!ENABLED) return;
    try {
      setVisible(localStorage.getItem(DISMISSED_KEY) !== 'true');
    } catch {
      // localStorage may be unavailable (private mode, sandbox); default to show.
      setVisible(true);
    }
  }, []);

  const handleDismiss = () => {
    setVisible(false);
    try {
      localStorage.setItem(DISMISSED_KEY, 'true');
    } catch {
      /* ignore */
    }
  };

  if (!ENABLED || !visible) return null;

  return (
    <Box
      role='status'
      width='100%'
      bg='blue.50'
      borderBottom='1px solid'
      borderColor='blue.200'
      px={{ base: '12px', md: '16px' }}
      py={{ base: '8px', md: '10px' }}
      data-testid='embed-origins-announcement-banner'
    >
      <Flex align='flex-start' gap={{ base: '8px', md: '12px' }} maxW='1400px' mx='auto'>
        <Icon as={FiInfo} color='blue.600' boxSize='16px' mt='2px' flexShrink={0} />
        <Text flex='1' fontSize={{ base: 'xs', md: 'sm' }} color='black.500' lineHeight='1.5'>
          <Text as='span' fontWeight='semibold'>
            Action required:
          </Text>{' '}
          Every site that embeds your data apps, AI workflows, or app-builder apps —{' '}
          <Text as='span' fontWeight='semibold'>
            including embeds that are already live
          </Text>{' '}
          — must be listed under this workspace&apos;s Allowed Origins. Sites that aren&apos;t
          listed will be blocked by the browser. Review yours under Settings →{' '}
          <Link
            as={RouterLink}
            to='/settings/embed-origins'
            color='blue.600'
            fontWeight='semibold'
            textDecoration='underline'
            whiteSpace='nowrap'
          >
            Allowed Origins
          </Link>
          .
        </Text>
        <CloseButton
          size='sm'
          onClick={handleDismiss}
          aria-label='Dismiss announcement'
          data-testid='embed-origins-announcement-dismiss'
          flexShrink={0}
        />
      </Flex>
    </Box>
  );
};

export default EmbedOriginsAnnouncementBanner;
