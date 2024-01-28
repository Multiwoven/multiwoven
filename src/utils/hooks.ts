type UseUiConfig = {
  maxContentWidth: number;
  contentPadding: number;
};

export const useUiConfig = (): UseUiConfig => {
  return {
    maxContentWidth: 1500,
    contentPadding: 30,
  };
};
