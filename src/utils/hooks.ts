type UseUiConfig = {
  contentContainerId: 'content-container';
  maxContentWidth: number;
  contentPadding: number;
};

export const useUiConfig = (): UseUiConfig => {
  return {
    contentContainerId: 'content-container',
    maxContentWidth: 1500,
    contentPadding: 30,
  };
};
