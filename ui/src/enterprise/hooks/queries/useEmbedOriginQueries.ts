import useQueryWrapper from '@/hooks/useQueryWrapper';
import { EmbedOriginScope, getEmbedOrigins } from '@/enterprise/services/embed-origins';

const useEmbedOriginQueries = () => {
  const useGetEmbedOrigins = (scope: EmbedOriginScope) =>
    useQueryWrapper(['embed-origins', scope], () => getEmbedOrigins(scope), {
      refetchOnMount: true,
      refetchOnWindowFocus: true,
      staleTime: 5000,
    });

  return { useGetEmbedOrigins };
};

export default useEmbedOriginQueries;
